pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import '../src/UniswapV2Pair.sol';
import '../src/UniswapV2ERC20.sol';
import '../src/UniswapV2Factory.sol';
import '../src/UniswapV2Router02.sol';
// import '../src/libraries/UniswapV2Library.sol';
import '../src/ERC20.sol';
import '../src/WETH9.sol';

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

contract dtt is ERC20 {

    constructor(uint256 initialSupply) ERC20("dtt", "DTT"){
        _mint(msg.sender, initialSupply);
        approve(msg.sender, initialSupply);
    }

}

contract weth9 is WETH9 {}

contract test is Test {

    token0 TokenA;
    token1 TokenB;

    address Token0;
    address Token1;
    address pairAddress;
    
    weth9 WETH;
    dtt DTT;

    UniswapV2Router02 router;
    UniswapV2Factory testFactory;

    address walletAddress;

    function setUp() public {
        
        // Set up contracts, factory, and pair
        TokenA = new token0(10000e18);
        TokenB = new token1(10000e18);

        DTT = new dtt(10000e18);

        walletAddress = address(1);
        testFactory = new UniswapV2Factory(address(this));

        testFactory.createPair(address(TokenA), address(TokenB));

        pairAddress = testFactory.getPair(address(TokenA), address(TokenB));

        address token0Address = address(IUniswapV2Pair(pairAddress).token0());

        Token0 = address(TokenA) == token0Address ? address(TokenA) : address(TokenB);
        Token1 = address(TokenA) == token0Address ? address(TokenB) : address(TokenA);

        WETH = new weth9();
        router = new UniswapV2Router02(address(testFactory), address(WETH));

    }

    function testQuote() public {

        assertEq(router.quote(1,100,200),2);
        assertEq(router.quote(2,200,100),1);

        vm.expectRevert();
        router.quote(0,100,200);
        vm.expectRevert();
        router.quote(1,0,200);
        vm.expectRevert();
        router.quote(1,100,0);

    }

    function testGetAmountOut() public {

        assertEq(router.getAmountOut(2,100,100), 1);
        
        vm.expectRevert();
        router.getAmountOut(0,100,100);
        vm.expectRevert();
        router.getAmountOut(2,0,100);
        vm.expectRevert();
        router.getAmountOut(2,100,0);

    }

    function testGetAmountIn() public {

        // Arithmetic over/underflow
        // assertEq(router.getAmountIn(1,100,100), 2);
        
        vm.expectRevert();
        router.getAmountIn(0,100,100);
        vm.expectRevert();
        router.getAmountIn(1,0,100);
        vm.expectRevert();
        router.getAmountIn(1,100,0);

    }

    function testGetAmountsOut() public {

        ERC20(Token0).approve(address(router), UINT256_MAX);
        ERC20(Token1).approve(address(router), UINT256_MAX);
        // Reverts
        // router.addLiquidity(
        //     Token0,
        //     Token1,
        //     10000,
        //     10000,
        //     0,
        //     0,
        //     address(this),
        //     UINT256_MAX
        // );

        address[] memory t = new address[](2);
        t[0] = Token0;
        t[1] = Token1;

        vm.expectRevert();
        router.getAmountsOut(2, t);

    }

    function testGetAmountsIn() public {

        ERC20(Token0).approve(address(router), UINT256_MAX);
        ERC20(Token1).approve(address(router), UINT256_MAX);
        // Reverts
        // router.addLiquidity(
        //     Token0,
        //     Token1,
        //     10000,
        //     10000,
        //     0,
        //     0,
        //     address(this),
        //     UINT256_MAX
        // );
        
        address[] memory t = new address[](2);
        t[0] = Token0;
        t[1] = Token1;

        vm.expectRevert();
        router.getAmountsIn(1, t);

    }

    function testRemoveLiquidityETHSupportingFeeOnTransferTokens() public {

        uint256 DTTAmount = 1e18;
        uint256 ETHAmount = 4e18;
        
        DTT.approve(address(router), UINT256_MAX);
        // router.addLiquidityETH(
        //     address(DTT), 
        //     DTTAmount, 
        //     DTTAmount, 
        //     ETHAmount, 
        //     address(this), 
        //     UINT256_MAX
        // );

    }

}