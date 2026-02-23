use anchor_lang::error_code;


#[error_code]
pub enum OxediumError {
    #[msg("Invalid Admin")]
    InvalidAdmin,

    #[msg("Overflow")]
    Overflow,

    #[msg("Invalid Pyth Account")]
    InvalidPythAccount,

    #[msg("Slippage greater than permissible")]
    HighSlippage,
    
    #[msg("Insufficient liquidity in the vault")]
    InsufficientLiquidity,

    #[msg("Stoptap activated")]
    StoptapActivated,

    #[msg("Overflow in mul")]
    OverflowInMul,

    #[msg("Overflow in div")]
    OverflowInDiv,

    #[msg("Overflow in sub")]
    OverflowInSub,

    #[msg("Overflow in add")]
    OverflowInAdd,

    #[msg("Oracle data too old")]
    OracleDataTooOld,

    #[msg("Overflow in cast")]
    OverflowInCast,

    #[msg("The fee exceeds 100%")]
    FeeExceeds,

    #[msg("Deviation must be greater than zero")]
    InvalidDeviation,
}