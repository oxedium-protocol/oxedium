use anchor_lang::error_code;


#[error_code]
pub enum OxediumError {
    #[msg("Invalid Admin")]
    InvalidAdmin,

    #[msg("Missing Account")]
    MissingAccount,

    #[msg("Invalid Signer")]
    InvalidSigner,

    #[msg("Invalid ATA")]
    InvalidATA,

    #[msg("Invalid Treasury")]
    InvalidTreasury,

    #[msg("Missing SPL Account")]
    MissingSPLAccount,

    #[msg("Invalid LP Amount")]
    InvalidLpAmount,

    #[msg("Divide by zero")]
    DivideByZero,

    #[msg("Overflow")]
    Overflow,

    #[msg("Invalid Pyth Account")]
    InvalidPythAccount,

    #[msg("Slippage greater than permissible")]
    HighSlippage,

    #[msg("Invalid token owner")]
    InvalidTokenOwner,
    
    #[msg("Insufficient liquidity in the vault")]
    InsufficientLiquidity,

    #[msg("Vault A not active")]
    PoolANotActive,

    #[msg("Vault B not active")]
    PoolBNotActive,

    #[msg("Stoptap activated")]
    StoptapActivated,

    #[msg("Price not available")]
    PriceNotAvailable,

    #[msg("High volatility")]
    HighVolatility,

    #[msg("Switch in Off mode")]
    SwitchOff,

    #[msg("Overflow in pow")]
    OverflowInPow,

    #[msg("Overflow in mul")]
    OverflowInMul,

    #[msg("Overflow in div")]
    OverflowInDiv,

    #[msg("Oracle data too old")]
    OracleDataTooOld,

    #[msg("Overflow in cast")]
    OverflowInCast,

    #[msg("The fee exceeds 100%")]
    FeeExceeds,
}