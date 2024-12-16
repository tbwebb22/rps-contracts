// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Escrow is Ownable2Step {
    bool public paused;
    IERC20 public moxie;
    uint256 public depositCount;

    error Paused();
    error AlreadyPaused();
    error AlreadyUnpaused();

    event Deposit(uint256 indexed depositId, uint256 indexed fid, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Pause();
    event Unpause();

    constructor(address _owner, address _moxie) Ownable(_owner) {
        moxie = IERC20(_moxie);
    }

    function deposit(uint256 _fid, uint256 _amount) external {
        if (paused) revert Paused();

        moxie.transferFrom(msg.sender, address(this), _amount);
        depositCount++;

        emit Deposit(depositCount, _fid, _amount);
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        _withdraw(_to, _amount);
    }

    function withdrawAll(address _to) external onlyOwner {
        _withdraw(_to, moxie.balanceOf(address(this)));
    }

    function pause() external onlyOwner {
        if (paused) revert AlreadyPaused();

        paused = true;

        emit Pause();
    }

    function unpause() external onlyOwner {
        if (!paused) revert AlreadyUnpaused();

        paused = false;

        emit Unpause();
    }

    function _withdraw(address _to, uint256 _amount) internal {
        moxie.transfer(_to, _amount);

        emit Withdraw(_to, _amount);
    }
}
