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

contract weth is WETH9 {

    

}

contract test is Test {

    token0 TokenA;
    token1 TokenB;

    address Token0;
    address Token1;
    address pairAddress;
    address pairAddress2;
    address WETHPairAddress;
    address DTTPairAddress;
    
    weth WETH;
    
    dtt DTT;
    dtt DTT2;

    UniswapV2Router02 router;
    UniswapV2Factory testFactory;

    address walletAddress;

    function setUp() public {
        
        TokenA = new token0(10000e18);
        TokenB = new token1(10000e18);

        testFactory = new UniswapV2Factory(address(this));

        testFactory.createPair(address(TokenA), address(TokenB));
        testFactory.setFeeTo(address(this));
        pairAddress = testFactory.getPair(address(TokenA), address(TokenB));

        address token0Address = address(IUniswapV2Pair(pairAddress).token0());

        Token0 = address(TokenA) == token0Address ? address(TokenA) : address(TokenB);
        Token1 = address(TokenA) == token0Address ? address(TokenB) : address(TokenA);

        DTT = new dtt(10000e18);
        DTT2 = new dtt(10000e18);

        WETH = new weth();

        router = new UniswapV2Router02(address(testFactory), address(WETH));
        
        // testFactory.createPair(address(WETH), address(WETHP));
        // WETHPairAddress = testFactory.getPair(address(WETH), address(WETHP));

        testFactory.createPair(address(DTT), address(WETH));
        pairAddress2 = testFactory.getPair(address(DTT), address(WETH));

        testFactory.createPair(address(DTT), address(DTT2));
        DTTPairAddress = testFactory.getPair(address(DTT), address(DTT2));

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

        assertEq(router.getAmountIn(1,100,100), 2);
        
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
        router.addLiquidity(
            Token0,
            Token1,
            10000,
            10000,
            0,
            0,
            address(this),
            UINT256_MAX
        );

        address[] memory t0 = new address[](1);
        t0[0] = Token0;

        vm.expectRevert();
        router.getAmountsOut(2, t0);

        address[] memory t = new address[](2);
        t[0] = Token0;
        t[1] = Token1;

        assertEq(router.getAmountsOut(2, t)[0], 2);
        assertEq(router.getAmountsOut(2, t)[1], 1);

    }

    function testGetAmountsIn() public {

        ERC20(Token0).approve(address(router), UINT256_MAX);
        ERC20(Token1).approve(address(router), UINT256_MAX);
        router.addLiquidity(
            Token0,
            Token1,
            10000,
            10000,
            0,
            0,
            address(this),
            UINT256_MAX
        );
        
        address[] memory t0 = new address[](1);
        t0[0] = Token0;


        vm.expectRevert();
        router.getAmountsIn(1, t0);

        address[] memory t = new address[](2);
        t[0] = Token0;
        t[1] = Token1;

        assertEq(router.getAmountsIn(1, t)[0], 2);
        assertEq(router.getAmountsIn(1, t)[1], 1);

    }

    function testRemoveLiquidityETHSupportingFeeOnTransferTokens() public {

        uint256 DTTAmount = 1e18;
        uint256 WETHAmount = 4e18;
        
        // ---- addLiquidity ----
        DTT.approve(address(router), UINT256_MAX);
        router.addLiquidityETH{value: WETHAmount}(
            address(DTT), 
            DTTAmount, 
            DTTAmount, 
            WETHAmount, 
            address(this), 
            UINT256_MAX
        );
        // ----------------------

        uint256 DTTInPair = DTT.balanceOf(pairAddress2);
        uint256 WETHInPair = WETH.balanceOf(pairAddress2);
        uint256 liquidity = IUniswapV2Pair(pairAddress2).balanceOf(address(this));
        uint256 totalSupply = IUniswapV2Pair(pairAddress2).totalSupply();
        uint256 NaiveDTTExpected = (DTTInPair * liquidity) / totalSupply;
        uint256 WETHExpected = (WETHInPair * liquidity) / totalSupply;

        IUniswapV2Pair(pairAddress2).approve(address(router), UINT256_MAX);
        // Reverts when using IWETH functions
        // router.removeLiquidityETHSupportingFeeOnTransferTokens(
        //     address(DTT),
        //     liquidity,
        //     NaiveDTTExpected,
        //     WETHExpected,
        //     address(this),
        //     UINT256_MAX
        // );

    }

    // ETH -> DTT
    function testSwapExactETHForTokensSupportingFeeOnTransferTokens() public {

        uint256 DTTAmount = 10e18;
        DTTAmount = DTTAmount * 1000 / 99;
        uint256 ETHAmount = 5e18;
        uint256 swapAmount = 1e18;

        // ---- addLiquidity ----
        DTT.approve(address(router), UINT256_MAX);
        router.addLiquidityETH{value: ETHAmount}(
            address(DTT), 
            DTTAmount, 
            DTTAmount, 
            ETHAmount, 
            address(this), 
            UINT256_MAX
        );
        // ----------------------

        address[] memory a = new address[](2);
        a[0] = address(WETH);
        a[1] = address(DTT);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount}(
            0,
            a,
            address(this),
            UINT256_MAX
        );

    }

    // DTT -> ETH
    function testSwapExactTokensForETHSupportingFeeOnTransferTokens() public {

        uint256 DTTAmount = 5e18;
        DTTAmount = DTTAmount * 1000 / 99;
        uint256 ETHAmount = 10e18;
        uint256 swapAmount = 1e18;

        // ---- addLiquidity ----
        DTT.approve(address(router), UINT256_MAX);
        router.addLiquidityETH{value: ETHAmount}(
            address(DTT), 
            DTTAmount, 
            DTTAmount, 
            ETHAmount, 
            address(this), 
            UINT256_MAX
        );
        // ----------------------

        address[] memory a = new address[](2);
        a[0] = address(DTT);
        a[1] = address(WETH);

        DTT.approve(address(router), UINT256_MAX);
        // Reverts when using IWETH functions
        // router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        //     swapAmount,
        //     0,
        //     a,
        //     address(this),
        //     UINT256_MAX
        // );

    }

    function testSwapExactTokensForTokensSupportingFeeOnTransferTokens() public {

        uint256 DTTAmount = 5e18;
        DTTAmount = DTTAmount * 1000 / 99;
        uint256 DTT2Amount = 5e18;
        uint256 amountIn = 1e18;

        // ---- addLiquidity ----
        DTT.approve(address(router), UINT256_MAX);
        DTT2.approve(address(router), UINT256_MAX);
        router.addLiquidity(
            address(DTT),
            address(DTT2),
            DTTAmount,
            DTT2Amount,
            DTTAmount,
            DTT2Amount,
            address(this),
            UINT256_MAX
        );
        // ----------------------

        address[] memory a = new address[](2);
        a[0] = address(DTT);
        a[1] = address(DTT2);

        DTT.approve(address(router), UINT256_MAX);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            a,
            address(this),
            UINT256_MAX
        );

    }

}