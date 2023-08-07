pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import '../src/UniswapV2Pair.sol';
import '../src/UniswapV2ERC20.sol';
import '../src/UniswapV2Factory.sol';
import '../src/ERC20.sol';

contract token0 is ERC20 {

    constructor(uint256 initialSupply) ERC20("token0", "T0"){
        _mint(address(msg.sender), initialSupply);
        approve(address(msg.sender), initialSupply);
    }

}

contract token1 is ERC20 {

    constructor(uint256 initialSupply) ERC20("token1", "T1"){
        _mint(msg.sender, initialSupply);
        approve(msg.sender, initialSupply);
    }

}

contract test is Test {

    UniswapV2Factory testFactory;
    UniswapV2Pair pairContract;
    
    token0 TokenA;
    token1 TokenB;
    address Token0;
    address Token1;

    address pairAddress;
    address walletAddress; // replaced with address(this) since it is the caller and not walletAddress
    uint256 MINIMUM_LIQUIDITY = 1000;
    uint112 reserves0;
    uint112 reserves1;

    address testAddress0 = address(1e18);
    address testAddress1 = address (2e18);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function setUp() public {
        
        // Set up contracts, factory, and pair
        TokenA = new token0(10000e18);
        TokenB = new token1(10000e18);

        walletAddress = address(1);

        // Set up factory and create token pair
        testFactory = new UniswapV2Factory(address(this));
        // testFactory.setFeeToSetter(address(this));
        // testFactory.setFeeTo(address(this));
        
        // testFactory.createPair(address(TokenA), address(TokenB));

        // pairAddress = testFactory.getPair(address(TokenA), address(TokenB));

        // address token0Address = address(IUniswapV2Pair(pairAddress).token0());

        // Token0 = address(TokenA) == token0Address ? address(TokenA) : address(TokenB);
        // Token1 = address(TokenA) == token0Address ? address(TokenB) : address(TokenA);

        // console.log("TokenA address: ", address(TokenA));
        // console.log("TokenB address: ", address(TokenB));
        // console.log("Token0 is ", Token0);
        // console.log("Token1 is ", Token1);
        
    }

    // helper function
    function getCreate2Address(address factoryAddress, address tokenA, address tokenB, bytes memory bytecode) public pure returns (address) {

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), 
                factoryAddress, 
                keccak256(abi.encodePacked(tokenA, tokenB)), 
                keccak256(bytecode)
            )
        );

        return address (uint160(uint(hash)));

    }    
    
    function testFeeToFeeToSetterAllPairsLength() public {

        assertEq(testFactory.feeTo(), address(0));
        assertEq(testFactory.feeToSetter(), address(this));
        assertEq(testFactory.allPairsLength(), 0);

    }

    function testCreatePair() public {

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        address create2Address = getCreate2Address(address(testFactory), address(TokenB), address(TokenA), bytecode);
        
        vm.expectEmit(true, true, true, true);
        emit PairCreated(address(TokenB), address(TokenA), create2Address, 1);
        testFactory.createPair(address(TokenA), address(TokenB));

        vm.expectRevert();
        testFactory.createPair(address(TokenA), address(TokenB));

        vm.expectRevert();
        testFactory.createPair(address(TokenB), address(TokenA));

        assertEq(testFactory.getPair(address(TokenA), address(TokenB)), create2Address);
        assertEq(testFactory.getPair(address(TokenB), address(TokenA)), create2Address);
        assertEq(testFactory.allPairs(0), create2Address);
        assertEq(testFactory.allPairsLength(), 1);

    }

    function testSetFeeTo() public {

        address other = address(1);
        
        vm.prank(other);
        vm.expectRevert();
        testFactory.setFeeTo(other);

        testFactory.setFeeTo(address(this));
        assertEq(testFactory.feeTo(), address(this));

    }

    function testSetFeeToSetter() public {

        address other = address(1);

        vm.prank(other);
        vm.expectRevert();
        testFactory.setFeeToSetter(other);

        testFactory.setFeeToSetter(other);
        assertEq(testFactory.feeToSetter(), other);

        vm.expectRevert();
        testFactory.setFeeToSetter(address(this));

    }

}