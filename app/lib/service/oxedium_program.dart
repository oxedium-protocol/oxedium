import 'package:crypto/crypto.dart';
import 'package:fixnum/fixnum.dart';
import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/evn.dart';
import 'package:oxedium_website/models/staked.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/service/config.dart';

class OxediumProgram {
  static const String programId = TYRBINE_PROGRAM_ID;

  static Future<String> getTreasuryAddress() async {
    var treasury = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "oxedium-seed".codeUnits,
      "treasury-seed".codeUnits,
    ], programId: Ed25519HDPublicKey.fromBase58(programId));
    return treasury.toBase58();
  }

  static Future<Message> staking(
      {required String signer,
      required Vault vault,
      required int amount}) async {
    final List<int> data = [];
    data.addAll(sha256
        .convert('global:staking'.codeUnits)
        .bytes
        .getRange(0, 8)
        .toList());
    data.addAll(Int64(amount).toBytes());

    final vaultPDA = await Ed25519HDPublicKey.findProgramAddress(
        seeds: ["vault-seed".codeUnits, base58decode(vault.mint)],
        programId: Ed25519HDPublicKey.fromBase58(programId));

    var lpMint = await Ed25519HDPublicKey.findProgramAddress(
        seeds: ["mint-seed".codeUnits, base58decode(vaultPDA.toBase58())],
        programId: Ed25519HDPublicKey.fromBase58(programId));

    var signerATA = await findAssociatedTokenAddress(
        owner: Ed25519HDPublicKey.fromBase58(signer),
        mint: Ed25519HDPublicKey.fromBase58(vault.mint));

    var signerLpATA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      base58decode(signer),
      base58decode(TokenProgram.programId),
      base58decode(lpMint.toBase58()),
    ], programId: AssociatedTokenAccountProgram.id);

    var stakerPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "staker-seed".codeUnits,
      base58decode(vaultPDA.toBase58()),
      base58decode(signer),
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var treasury = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "oxedium-seed".codeUnits,
      "treasury-seed".codeUnits,
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var treasuryATA = await findAssociatedTokenAddress(
        owner: treasury, mint: Ed25519HDPublicKey.fromBase58(vault.mint));

    List<Instruction> instructions = [];

    if (vault.mint == "So11111111111111111111111111111111111111112") {
      final getWsolATA = await solanaClient.getAssociatedTokenAccount(
          owner: Ed25519HDPublicKey.fromBase58(signer),
          mint: Ed25519HDPublicKey.fromBase58(vault.mint));
      final lamports =
          await solanaClient.rpcClient.getMinimumBalanceForRentExemption(165) +
              amount;
      if (getWsolATA == null) {
        final findATA = await findAssociatedTokenAddress(
            owner: Ed25519HDPublicKey.fromBase58(signer),
            mint: Ed25519HDPublicKey.fromBase58(vault.mint));
        instructions.add(
          AssociatedTokenAccountInstruction.createAccount(
              funder: Ed25519HDPublicKey.fromBase58(signer),
              address: findATA,
              owner: Ed25519HDPublicKey.fromBase58(signer),
              mint: Ed25519HDPublicKey.fromBase58(vault.mint)),
        );
      }
      instructions.addAll([
        SystemInstruction.transfer(
          fundingAccount: Ed25519HDPublicKey.fromBase58(signer),
          recipientAccount: signerATA,
          lamports: lamports,
        ),
        TokenInstruction.syncNative(nativeTokenAccount: signerATA),
      ]);
    }

    instructions.add(
      Instruction(
        programId: Ed25519HDPublicKey.fromBase58(programId),
        accounts: [
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(signer), isSigner: true),
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(vault.mint),
              isSigner: false),
          AccountMeta.writeable(pubKey: lpMint, isSigner: false),
          AccountMeta.writeable(pubKey: signerATA, isSigner: false),
          AccountMeta.writeable(pubKey: signerLpATA, isSigner: false),
          AccountMeta.writeable(pubKey: vaultPDA, isSigner: false),
          AccountMeta.writeable(pubKey: stakerPDA, isSigner: false),
          AccountMeta.writeable(pubKey: treasury, isSigner: false),
          AccountMeta.writeable(pubKey: treasuryATA, isSigner: false),
          AccountMeta.readonly(
              pubKey: AssociatedTokenAccountProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: SystemProgram.id, isSigner: false),
        ],
        data: ByteArray(data),
      ),
    );

    if (vault.mint == "So11111111111111111111111111111111111111112") {
      instructions.addAll([
        TokenInstruction.closeAccount(
            accountToClose: signerATA,
            destination: Ed25519HDPublicKey.fromBase58(signer),
            owner: Ed25519HDPublicKey.fromBase58(signer)),
      ]);
    }

    return Message(instructions: instructions);
  }

  static Future<Message> unstaking(
      {required String signer,
      required Staked stake,
      required int amount}) async {
    final List<int> data = [];

    data.addAll(sha256
        .convert('global:unstaking'.codeUnits)
        .bytes
        .getRange(0, 8)
        .toList());
    data.addAll(Int64(amount).toBytes());

    final vaultPDA = await Ed25519HDPublicKey.findProgramAddress(
        seeds: ["vault-seed".codeUnits, base58decode(stake.mint)],
        programId: Ed25519HDPublicKey.fromBase58(programId));

    var lpMint = await Ed25519HDPublicKey.findProgramAddress(
        seeds: ["mint-seed".codeUnits, base58decode(vaultPDA.toBase58())],
        programId: Ed25519HDPublicKey.fromBase58(programId));

    var signerATA = await findAssociatedTokenAddress(
        owner: Ed25519HDPublicKey.fromBase58(signer),
        mint: Ed25519HDPublicKey.fromBase58(stake.mint));

    var signerLpATA = await findAssociatedTokenAddress(
        owner: Ed25519HDPublicKey.fromBase58(signer), mint: lpMint);

    var stakerPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "staker-seed".codeUnits,
      base58decode(vaultPDA.toBase58()),
      base58decode(signer),
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var treasury = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "oxedium-seed".codeUnits,
      "treasury-seed".codeUnits,
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var treasuryATA = await findAssociatedTokenAddress(
        owner: treasury, mint: Ed25519HDPublicKey.fromBase58(stake.mint));

    final instructions = <Instruction>[];

    if (stake.mint == "So11111111111111111111111111111111111111112") {
      final getWsolATA = await solanaClient.getAssociatedTokenAccount(
          owner: Ed25519HDPublicKey.fromBase58(signer),
          mint: Ed25519HDPublicKey.fromBase58(stake.mint));

      if (getWsolATA == null) {
        final findATA = await findAssociatedTokenAddress(
            owner: Ed25519HDPublicKey.fromBase58(signer),
            mint: Ed25519HDPublicKey.fromBase58(stake.mint));
        instructions.add(
          AssociatedTokenAccountInstruction.createAccount(
              funder: Ed25519HDPublicKey.fromBase58(signer),
              address: findATA,
              owner: Ed25519HDPublicKey.fromBase58(signer),
              mint: Ed25519HDPublicKey.fromBase58(stake.mint)),
        );
      }
    }

    instructions.add(
      Instruction(
        programId: Ed25519HDPublicKey.fromBase58(programId),
        accounts: [
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(signer), isSigner: true),
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(stake.mint),
              isSigner: false),
          AccountMeta.writeable(pubKey: lpMint, isSigner: false),
          AccountMeta.writeable(pubKey: signerATA, isSigner: false),
          AccountMeta.writeable(pubKey: signerLpATA, isSigner: false),
          AccountMeta.writeable(pubKey: vaultPDA, isSigner: false),
          AccountMeta.writeable(pubKey: stakerPDA, isSigner: false),
          AccountMeta.writeable(pubKey: treasury, isSigner: false),
          AccountMeta.writeable(pubKey: treasuryATA, isSigner: false),
          AccountMeta.readonly(
              pubKey: AssociatedTokenAccountProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: SystemProgram.id, isSigner: false),
        ],
        data: ByteArray(data),
      ),
    );

    if (stake.mint == "So11111111111111111111111111111111111111112") {
      instructions.addAll([
        TokenInstruction.closeAccount(
            accountToClose: signerATA,
            destination: Ed25519HDPublicKey.fromBase58(signer),
            owner: Ed25519HDPublicKey.fromBase58(signer)),
      ]);
    }

    return Message(instructions: instructions);
  }

  static Future<Message> claim(
      {required String signer, required String mint}) async {
    final List<int> data = [];
    data.addAll(
        sha256.convert('global:claim'.codeUnits).bytes.getRange(0, 8).toList());

    final vaultPDA = await Ed25519HDPublicKey.findProgramAddress(
        seeds: ["vault-seed".codeUnits, base58decode(mint)],
        programId: Ed25519HDPublicKey.fromBase58(programId));

    var lpMint = await Ed25519HDPublicKey.findProgramAddress(
        seeds: ["mint-seed".codeUnits, vaultPDA.bytes],
        programId: Ed25519HDPublicKey.fromBase58(programId));

    var signerATA = await findAssociatedTokenAddress(
        owner: Ed25519HDPublicKey.fromBase58(signer),
        mint: Ed25519HDPublicKey.fromBase58(mint));

    var signerLpATA = await findAssociatedTokenAddress(
        owner: Ed25519HDPublicKey.fromBase58(signer), mint: lpMint);

    var stakerPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "staker-seed".codeUnits,
      vaultPDA.bytes,
      base58decode(signer),
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var treasuryPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "oxedium-seed".codeUnits,
      "treasury-seed".codeUnits,
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var treasuryATA = await findAssociatedTokenAddress(
        owner: treasuryPDA, mint: Ed25519HDPublicKey.fromBase58(mint));

    final instructions = <Instruction>[];

    if (mint == "So11111111111111111111111111111111111111112") {
      final getWsolATA = await solanaClient.getAssociatedTokenAccount(
          owner: Ed25519HDPublicKey.fromBase58(signer),
          mint: Ed25519HDPublicKey.fromBase58(mint));
      if (getWsolATA == null) {
        final findATA = await findAssociatedTokenAddress(
            owner: Ed25519HDPublicKey.fromBase58(signer),
            mint: Ed25519HDPublicKey.fromBase58(mint));
        instructions.add(
          AssociatedTokenAccountInstruction.createAccount(
              funder: Ed25519HDPublicKey.fromBase58(signer),
              address: findATA,
              owner: Ed25519HDPublicKey.fromBase58(signer),
              mint: Ed25519HDPublicKey.fromBase58(mint)),
        );
      }
    }

    instructions.add(Instruction(
        programId: Ed25519HDPublicKey.fromBase58(programId),
        accounts: [
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(signer), isSigner: true),
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(mint), isSigner: false),
          AccountMeta.writeable(pubKey: lpMint, isSigner: false),
          AccountMeta.writeable(pubKey: signerLpATA, isSigner: false),
          AccountMeta.writeable(pubKey: signerATA, isSigner: false),
          AccountMeta.writeable(pubKey: stakerPDA, isSigner: false),
          AccountMeta.writeable(pubKey: vaultPDA, isSigner: false),
          AccountMeta.writeable(pubKey: treasuryPDA, isSigner: false),
          AccountMeta.writeable(pubKey: treasuryATA, isSigner: false),
          AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: SystemProgram.id, isSigner: false),
        ],
        data: ByteArray(data)));

    if (mint == "So11111111111111111111111111111111111111112") {
      instructions.addAll([
        TokenInstruction.closeAccount(
            accountToClose: signerATA,
            destination: Ed25519HDPublicKey.fromBase58(signer),
            owner: Ed25519HDPublicKey.fromBase58(signer)),
      ]);
    }

    return Message(instructions: instructions);
  }

  static Future<Message> swap({required String signer, required int amount, required Vault vaultA, required Vault vaultB, required bool simulation}) async {
    final List<int> data = [];
    data.addAll(sha256.convert('global:swap'.codeUnits).bytes.getRange(0, 8).toList());
    // Input
    data.addAll(Int64(amount).toBytes());
    // Partner fee
    data.addAll(Int64(0).toBytes());
    // Transaction simulation
    data.addAll(Int64(simulation ? 1 : 0).toBytes());

    final vaultAPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "vault-seed".codeUnits,
      base58decode(vaultA.mint)
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    final vaultBPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "vault-seed".codeUnits,
      base58decode(vaultB.mint)
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var vaultAsignerATA = await findAssociatedTokenAddress(owner: Ed25519HDPublicKey.fromBase58(signer), mint: Ed25519HDPublicKey.fromBase58(vaultA.mint));

    var vaultBsignerATA = await findAssociatedTokenAddress(owner: Ed25519HDPublicKey.fromBase58(signer), mint: Ed25519HDPublicKey.fromBase58(vaultB.mint));

    var treasury = await Ed25519HDPublicKey.findProgramAddress(seeds: [
      "oxedium-seed".codeUnits,
      "treasury-seed".codeUnits,
    ], programId: Ed25519HDPublicKey.fromBase58(programId));

    var tokenAtreasuryATA = await findAssociatedTokenAddress(owner: treasury, mint: Ed25519HDPublicKey.fromBase58(vaultA.mint));

    var tokenBtreasuryATA = await findAssociatedTokenAddress(owner: treasury, mint: Ed25519HDPublicKey.fromBase58(vaultB.mint));

    final instructions = <Instruction>[];

    if (vaultA.mint == "So11111111111111111111111111111111111111112" && !simulation) {
    final getWsolATA = await solanaClient.getAssociatedTokenAccount(owner: Ed25519HDPublicKey.fromBase58(signer), mint: Ed25519HDPublicKey.fromBase58(vaultA.mint));
    final lamports = await solanaClient.rpcClient.getMinimumBalanceForRentExemption(165) + amount;
    if (getWsolATA == null) {
      instructions.add(
        AssociatedTokenAccountInstruction.createAccount(
        funder: Ed25519HDPublicKey.fromBase58(signer), 
        address: vaultAsignerATA, 
        owner: Ed25519HDPublicKey.fromBase58(signer), 
        mint: Ed25519HDPublicKey.fromBase58(vaultA.mint)),
      );
    }
    instructions.addAll([
      SystemInstruction.transfer(
        fundingAccount: Ed25519HDPublicKey.fromBase58(signer),
        recipientAccount: vaultAsignerATA,
        lamports: lamports,
      ),
      TokenInstruction.syncNative(nativeTokenAccount: vaultAsignerATA),
    ]);
  }

  instructions.add(Instruction(
        programId: Ed25519HDPublicKey.fromBase58(programId), 
        accounts: [
          AccountMeta.writeable(pubKey: Ed25519HDPublicKey.fromBase58(signer), isSigner: true),
          AccountMeta.writeable(pubKey: Ed25519HDPublicKey.fromBase58(vaultA.mint), isSigner: false),
          AccountMeta.writeable(pubKey: Ed25519HDPublicKey.fromBase58(vaultB.mint), isSigner: false),
          AccountMeta.writeable(pubKey: Ed25519HDPublicKey.fromBase58(vaultA.pythOracle), isSigner: false),
          AccountMeta.writeable(pubKey: Ed25519HDPublicKey.fromBase58(vaultB.pythOracle), isSigner: false),
          AccountMeta.writeable(pubKey: vaultAsignerATA, isSigner: false),
          AccountMeta.writeable(pubKey: vaultBsignerATA, isSigner: false),
          AccountMeta.writeable(pubKey: vaultAPDA, isSigner: false),
          AccountMeta.writeable(pubKey: vaultBPDA, isSigner: false),
          AccountMeta.writeable(pubKey: treasury, isSigner: false),
          AccountMeta.writeable(pubKey: tokenAtreasuryATA, isSigner: false),
          AccountMeta.writeable(pubKey: tokenBtreasuryATA, isSigner: false),
          // Partner account
          AccountMeta.writeable(pubKey: Ed25519HDPublicKey.fromBase58(programId), isSigner: false),

          AccountMeta.readonly(pubKey: AssociatedTokenAccountProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: TokenProgram.id, isSigner: false),
          AccountMeta.readonly(pubKey: SystemProgram.id, isSigner: false),
        ], 
        data: ByteArray(data)));

    if (vaultA.mint == "So11111111111111111111111111111111111111112" && !simulation) {
      instructions.addAll([
        TokenInstruction.closeAccount(
          accountToClose: vaultAsignerATA, 
          destination: Ed25519HDPublicKey.fromBase58(signer), 
          owner: Ed25519HDPublicKey.fromBase58(signer)),
      ]);
    }
    return Message(instructions: instructions);
  }
}
