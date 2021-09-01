// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DoublyLinkedNode {
    address private _parent;
    address private _child;
    
    constructor(address parent, address child){
        if (parent != address(0x0)) {
            _parent = parent;
        } else {
            _parent = address(this);
        }

        if (child != address(0x0)) {
            _child = child;
        } else {
            _child = address(this);
        }
    }

    function addChild(address newChild) internal {
        DoublyLinkedNode(_child).changeParent(newChild);
        _child=newChild;
    }

    function changeParent(address parent) public {
        require(msg.sender == _parent,"Only the parent can ask to be changed");
        _parent=parent;
    }

    function delist() internal {
        DoublyLinkedNode(_parent).removeChild();
        DoublyLinkedNode(_child).changeParent(_parent);
        _parent = address(this);
        _child = address(this);        
    }

    function removeChild() public {
        require(msg.sender == _child,"Only the child can ask to be removed");
        _child=DoublyLinkedNode(_child).Child();
    }
    
    function Parent() public view returns(address) {
        return _parent;
    }
    
    function Child() public view returns(address) {
        return _child;
    }
}

//SisyphusGambleVenues is a registry of the Sisyphus gamble venues, it's also the guard of the Circular Doubly Linked List
contract SisyphusGambleVenues is DoublyLinkedNode(address(0x0),address(0x0)) {
    event  NewSisyphusGamble(address indexed sisyphusGamble, IERC20 indexed token, uint256 startingPrize, uint256 minGamble, uint8 weight, uint24 gamblingBlocks);

    function newSisyphusGamble(IERC20 token, uint256 startingPrize, uint256 minGamble, uint8 weight, uint24 gamblingBlocks) public returns(address) {
        require(minGamble <= startingPrize,"Starting prize must be at least as much as a minimum gamble");

        SisyphusGamble l = new SisyphusGamble(token, minGamble, weight, gamblingBlocks, address(this), Child());
        addChild(address(l));

        require(token.transferFrom(msg.sender, address(l), startingPrize), "Unable to transfer the starting fund amount");
        emit NewSisyphusGamble(address(l), token, startingPrize, minGamble, weight, gamblingBlocks);

        return address(l);
    }

    struct sisyphusGamble { 
        address sisyphusGamble;
        uint8   weight;
        uint24  gamblingBlocks;
        IERC20  token;
        uint256 totalPrize;
        address lastGambler;
        uint256 endBlock;
        uint256 minGamble;
    }
    
    //Covert the Doubly Linked List representation to an array
    function getSisyphusGambleVenues() public view returns(sisyphusGamble[] memory){
        uint256 length = 0;
        for (address c=this.Child(); c != address(this); c=DoublyLinkedNode(c).Child()) {
            length++;
        }
        
        uint256 i = 0;
        sisyphusGamble[] memory ll = new sisyphusGamble[](length);
        for (address c=this.Child(); c != address(this); c=DoublyLinkedNode(c).Child()) {
            SisyphusGamble l = SisyphusGamble(c);
            ll[i] = sisyphusGamble(c,l.weight(),l.gamblingBlocks(),l.token(),l.totalPrize(),l.lastGambler(),l.endBlock(),l.minGamble());
            i++;
        }
    
        return ll;
    }
}


contract SisyphusGamble is DoublyLinkedNode {
    address public  lastGambler;
    uint256 public  endBlock;
    uint256 public  minGamble;
    
    //Constant after initialization
    IERC20  public  token;
    uint8   public  weight;
    uint24  public  gamblingBlocks;

    event           Gamble(address indexed gambler, uint256 totalPrize, uint256 endBlock, uint256 newMinGamble);
    event           ClaimPrize(address indexed winner, uint256 totalPrize);
    
    constructor(IERC20 token_, uint256 minGamble_, uint8 weight_, uint24 gamblingBlocks_, address parent_, address child_)
    DoublyLinkedNode(parent_, child_) {
        require(minGamble_ > 0,"Minimum gamble must be a non zero amount");
        require(gamblingBlocks_ > 0,"Gambling blocks must be a non zero quantity");

        token=token_;
        minGamble=minGamble_;
        weight=weight_;
        gamblingBlocks=gamblingBlocks_;
        endBlock=type(uint256).max;
    }
    
    function gamble(uint256 amount) public returns(uint256) {
        require(amount >= minGamble,"Gamble more to partecipate");
        require(block.number < endBlock,"This gambling session has already closed");
        
        lastGambler=msg.sender;
        endBlock=block.number+gamblingBlocks;

        //This is an exponential moving average (a*minGamble  + (1-a)*amount) where a = (2**weight - 1)/2**weight
        //weight=255: minGamble is constant, unless amount - minGamble >= 2^255, but even then the change is +1.
        //weight=1: minGamble equal to the last amount. 
        //amount - minGamble >= 0 so it's never decreasing.
        minGamble += (amount - minGamble) >> weight;
        
        require(token.transferFrom(msg.sender, address(this), amount), "Unable to transfer the gambled amount");
        emit Gamble(msg.sender, totalPrize(), endBlock, minGamble);

        return endBlock;
    }
    
    function claimPrize() public {
        require(msg.sender == lastGambler,"You're not the last gambler");
        require(block.number >= endBlock,"Not enough blocks have passed since the last gamble");

        uint256 amount = totalPrize();
        require(token.transfer(msg.sender, amount));
        emit ClaimPrize(msg.sender, amount);
        
        super.delist();
        selfdestruct(payable(msg.sender));
    }

    function totalPrize() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
}