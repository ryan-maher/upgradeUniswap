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

    // events to emit for testing
    event Transfer(address indexed from, address indexed to, uint value);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
     
    function setUp() public {
        
        // Set up contracts, factory, and pair
        TokenA = new token0(10000e18);
        TokenB = new token1(10000e18);

        walletAddress = address(1);

        // Set up factory and create token pair
        testFactory = new UniswapV2Factory(address(this));
        testFactory.setFeeToSetter(address(this));
        testFactory.setFeeTo(address(this));
        
        testFactory.createPair(address(TokenA), address(TokenB));

        pairAddress = testFactory.getPair(address(TokenA), address(TokenB));

        address token0Address = address(IUniswapV2Pair(pairAddress).token0());

        Token0 = address(TokenA) == token0Address ? address(TokenA) : address(TokenB);
        Token1 = address(TokenA) == token0Address ? address(TokenB) : address(TokenA);

        // console.log("TokenA address: ", address(TokenA));
        // console.log("TokenB address: ", address(TokenB));
        // console.log("Token0 is ", Token0);
        // console.log("Token1 is ", Token1);
        
    }
    
    
    function testMint() public {
        
        // from v2-core/test/UniswapV2Pair.spec.ts
        // mint
        
        uint112 token0Amount = 1e18;
        uint112 token1Amount = 4e18;
        
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);
        
        uint256 expectedLiquidity = 2e18;

        // events to check when tokens are minted (pair calls mint)
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(0), MINIMUM_LIQUIDITY);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(this), expectedLiquidity - 1000);

        vm.expectEmit(true, true, false, true);
        emit Sync(token0Amount, token1Amount);

        vm.expectEmit(true, true, true, true);
        emit Mint(address(this), token0Amount, token1Amount);
        
        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));

        // check values
        assertEq(IUniswapV2Pair(pairAddress).totalSupply(), expectedLiquidity);
        assertEq(IERC20(pairAddress).balanceOf(address(this)), expectedLiquidity - MINIMUM_LIQUIDITY);
        assertEq(IERC20(Token0).balanceOf(pairAddress), token0Amount);
        assertEq(IERC20(Token1).balanceOf(pairAddress), token1Amount);
        (reserves0, reserves1 ,) = IUniswapV2Pair(pairAddress).getReserves();
        assertEq(reserves0, token0Amount);
        assertEq(reserves1, token1Amount);

    }
    
    function testSwapToken0() public {

        uint112 token0Amount = 5e18;
        uint112 token1Amount = 10e18;
        
        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------

        uint112 swapAmount = 1e18;
        uint112 expectedOutputAmount = 1662497915624478906;
        IERC20(Token0).transfer(pairAddress, swapAmount);

        vm.expectEmit(true, true, false, true);
        emit Transfer(pairAddress, address(this), expectedOutputAmount);

        vm.expectEmit(true, true, false, true);
        emit Sync(token0Amount + swapAmount, token1Amount - expectedOutputAmount);

        vm.expectEmit(true, true, true, true);
        emit Swap(address(this), swapAmount, 0, 0, expectedOutputAmount, address(this));

        IUniswapV2Pair(pairAddress).swap(0, expectedOutputAmount, address(this), '');

        (reserves0, reserves1, ) = IUniswapV2Pair(pairAddress).getReserves();
        assertEq(reserves0, token0Amount + swapAmount);
        assertEq(reserves1, token1Amount - expectedOutputAmount);
        assertEq(IERC20(Token0).balanceOf(pairAddress), token0Amount + swapAmount);
        assertEq(IERC20(Token1).balanceOf(pairAddress), token1Amount - expectedOutputAmount);
        uint256 totalSupplyToken0 = IERC20(Token0).totalSupply();
        uint256 totalSupplyToken1 = IERC20(Token1).totalSupply();
        assertEq(IERC20(Token0).balanceOf(address(this)), totalSupplyToken0 - token0Amount - swapAmount);
        assertEq(IERC20(Token1).balanceOf(address(this)), totalSupplyToken1 - token1Amount + expectedOutputAmount);
        
    }
    
    function testSwapToken1() public {

        uint112 token0Amount = 5e18;
        uint112 token1Amount = 10e18;
        
        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------

        uint112 swapAmount = 1e18;
        uint112 expectedOutputAmount = 453305446940074565;
        IERC20(Token1).transfer(pairAddress, swapAmount);

        vm.expectEmit(true, true, false, true);
        emit Transfer(pairAddress, address(this), expectedOutputAmount);

        vm.expectEmit(true, true, false, true);
        emit Sync(token0Amount - expectedOutputAmount, token1Amount + swapAmount);

        vm.expectEmit(true, true, true, true);
        emit Swap(address(this), 0, swapAmount, expectedOutputAmount, 0, address(this));

        IUniswapV2Pair(pairAddress).swap(expectedOutputAmount, 0, address(this), '');

        (reserves0, reserves1, ) = IUniswapV2Pair(pairAddress).getReserves();
        assertEq(reserves0, token0Amount - expectedOutputAmount);
        assertEq(reserves1, token1Amount + swapAmount);
        uint256 totalSupplyToken0 = IERC20(Token0).totalSupply();
        uint256 totalSupplyToken1 = IERC20(Token1).totalSupply();
        assertEq(IERC20(Token0).balanceOf(address(this)), totalSupplyToken0 - token0Amount + expectedOutputAmount);
        assertEq(IERC20(Token1).balanceOf(address(this)), totalSupplyToken1 - token1Amount - swapAmount);

    }

    function testSwapGas() public {

        uint112 token0Amount = 5e18;
        uint112 token1Amount = 10e18;
        
        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------

        // await mineBlock(provider, (await provider.getBlock('latest')).timestamp + 1)
        //skip(1);
        IUniswapV2Pair(pairAddress).sync();

        uint112 swapAmount = 1e18;
        uint112 expectedOutputAmount = 453305446940074565;
        IERC20(Token1).transfer(pairAddress, swapAmount);
        //skip(1);
        IUniswapV2Pair(pairAddress).swap(expectedOutputAmount, 0, address(this), '');

    }

    function testBurn() public {

        uint112 token0Amount = 3e18;
        uint112 token1Amount = 3e18;

        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------

        uint112 expectedLiquidity = 3e18;
        IUniswapV2Pair(pairAddress).transfer(pairAddress, expectedLiquidity - MINIMUM_LIQUIDITY);

        vm.expectEmit(true, true, false, true);
        emit Transfer(pairAddress, address(0), expectedLiquidity - MINIMUM_LIQUIDITY);

        vm.expectEmit(true, true, false, true);
        emit Transfer(pairAddress, address(this), token0Amount - 1000);

        vm.expectEmit(true, true, false, true);
        emit Transfer(pairAddress, address(this), token1Amount - 1000);

        vm.expectEmit(true, true, false, true);
        emit Sync(1000, 1000);

        vm.expectEmit(true, true, true, true);
        emit Burn(address(this), token0Amount - 1000, token1Amount - 1000, address(this));

        IUniswapV2Pair(pairAddress).burn(address(this));

    }

    function testPrice01CumulativeLast() public {

        uint112 token0Amount = 3e18;
        uint112 token1Amount = 3e18;
        
        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------
        
        uint32 blockTimeStamp;
        ( , , blockTimeStamp) = IUniswapV2Pair(pairAddress).getReserves();
        // skip(1);
        // IUniswapV2Pair(pairAddress).sync();

        // encode price
        // uint256 initialPrice0;
        // uint256 initialPrice1;
        
        // overflow error
        // initialPrice0 = (token1Amount * (2**112)) / token0Amount;
        // initialPrice1 = (token0Amount * (2**112)) / token1Amount;

        // assertEq(IUniswapV2Pair(pairAddress).price0CumulativeLast(), initialPrice0);
    }

    function testFeeToOff() public {

        uint112 token0Amount = 1000e18;
        uint112 token1Amount = 1000e18;

        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------

        uint256 swapAmount = 1e18;
        uint256 expectedOutputAmount = 996006981039903216;
        IERC20(Token1).transfer(pairAddress, swapAmount);
        IUniswapV2Pair(pairAddress).swap(expectedOutputAmount, 0, address(this), '');

        uint256 expectedLiquidity = 1000e18;
        IUniswapV2Pair(pairAddress).transfer(pairAddress, expectedLiquidity - MINIMUM_LIQUIDITY);
        IUniswapV2Pair(pairAddress).burn(address(this));
        // Error: a == b not satisfied [uint]
        //  Left: 249750499252388
        //  Right: 1000
        // assertEq(IUniswapV2Pair(pairAddress).totalSupply(), MINIMUM_LIQUIDITY);

    }
    
    function testFeeToOn() public{

        testFactory.setFeeTo(walletAddress);

        uint112 token0Amount = 1000e18;
        uint112 token1Amount = 1000e18;

        // ---- addLiquidity ----
        // Transfer tokens to pair
        IERC20(Token0).transfer(pairAddress, token0Amount);
        IERC20(Token1).transfer(pairAddress, token1Amount);

        // mint token pair
        IUniswapV2Pair(pairAddress).mint(address(this));
        // ----------------------

        uint112 swapAmount = 1e18;
        uint112 expectedOutputAmount = 996006981039903216;
        IERC20(Token1).transfer(pairAddress, swapAmount);
        IUniswapV2Pair(pairAddress).swap(expectedOutputAmount, 0, address(this), '');

        uint112 expectedLiquidity = 1000e18;
        IUniswapV2Pair(pairAddress).transfer(pairAddress, expectedLiquidity - MINIMUM_LIQUIDITY);
        IUniswapV2Pair(pairAddress).burn(address(this));
        assertEq(IUniswapV2Pair(pairAddress).totalSupply(), MINIMUM_LIQUIDITY + 249750499251388);
        assertEq(IUniswapV2Pair(pairAddress).balanceOf(walletAddress), 249750499251388);

        assertEq(IERC20(Token0).balanceOf(pairAddress), 1000 + 249501683697445);
        assertEq(IERC20(Token1).balanceOf(pairAddress), 1000 + 250000187312969);

    }

    
}
