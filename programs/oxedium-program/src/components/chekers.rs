use anchor_lang::prelude::*;
use crate::{states::{Vault, Treasury}, utils::TyrbineError};

/// Checks if the given signer is the admin of the treasury.
/// Returns `InvalidAdmin` error if not.
pub fn check_admin(treasury_pda: &Treasury, signer: &Signer) -> Result<()> {
    if signer.key() != treasury_pda.admin {
        return Err(TyrbineError::InvalidAdmin.into());
    }
    
    Ok(())
}

/// Checks if the vault and treasury are not under a "stoptap" condition.
/// Returns `StoptapActivated` error if either the vault is inactive or the treasury stoptap is enabled.
pub fn check_stoptap(vault: &Vault, treasury_pda: &Treasury) -> Result<()> {
    if !vault.is_active {
        return Err(TyrbineError::StoptapActivated.into());
    }

    if treasury_pda.stoptap {
        return Err(TyrbineError::StoptapActivated.into());
    }
    
    Ok(())
}