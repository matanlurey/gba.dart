/// ARM7/TDMI has 6 modes: [user], [system], [irq], [fiq], [und], [abt].
///
/// The default is [user] mode. Certain events will trigger a mode switch. Some
/// modes cause an alternate set of registers to be swapped in, effectively
/// replacing the current set of registers until the mode is exited.
enum Arm7TdmiProcessorMode {
  /// This is the default mode.
  user,

  /// This mode is entered when a _fast interrupt request_ is triggered.
  ///
  /// Since all of the hardware interrupts on the GBA generate IRQs, this mode
  /// goes unused by default, though it would be possible to switch to this mode
  /// manually using the `msr` instruction.
  ///
  /// ## Banked registers
  ///
  /// - `r{8...14}_fiq` replace `r{8...14}`.
  /// - Current `CPSR` gets svaed into the `SPSR_fiq` register.
  fiq,

  /// This mode is entered when an _interrupt request_ is triggered.
  ///
  /// Any interrupt handler on the GBA will be called in IRQ mode.
  ///
  /// ## Banked registers
  ///
  /// - `r13_irq` and `r14_irq` replace `r13` and `r14`.
  /// - Current `CPSR` gets saved into the `SPSR_irq` register.
  irq,

  /// Supervisor mode.
  ///
  /// Entered when a SWI (_software interrupt_) is executed.
  ///
  /// The GBA enters this state when calling the BIOS via `SWI` instructions.
  ///
  /// ## Banked registers
  ///
  /// - `r13_svc` and `r14_svc` replace `r13` and `r14`.
  /// - Current `CPSR` gets saved into the `SPSR_svc` register.
  svc,

  /// Abort mode.
  ///
  /// Entered after data or instruction prefetch abort
  ///
  /// ## Banked registers
  ///
  /// - `r13_abt` and `r14_abt` replace `r13` and `r14`.
  /// - Current `CPSR` gets saved into the `SPSR_abt` register.
  abt,

  /// Undefined mode.
  ///
  /// Entered when an undefined instruction is executed.
  ///
  /// ## Banked registers
  ///
  /// - `r13_und` and `r14_und` replace `r13` and `r14`.
  /// - Current `CPSR` gets saved into the `SPSR_und` register.
  und,

  /// This is intended to be a priveleged user mode for the operating system.
  ///
  /// > NOTE: As far as most can tell it is otherwise the same as [user] mode;
  /// > not sure if the GBA ever enters [system] mode during BIOS calls.
  system,
}

extension Arm7TdmiProcessorModeValues on Arm7TdmiProcessorMode {
  /// Returns the exact bit-backed value (as an [int]) for the current mode.
  int get bits {
    switch (this) {
      case Arm7TdmiProcessorMode.user:
        return 0x10; // 1_0000
      case Arm7TdmiProcessorMode.fiq:
        return 0x11; // 1_0001
      case Arm7TdmiProcessorMode.irq:
        return 0x12; // 1_0010
      case Arm7TdmiProcessorMode.svc:
        return 0x13; // 1_0011
      case Arm7TdmiProcessorMode.abt:
        return 0x17; // 1_0111
      case Arm7TdmiProcessorMode.und:
        return 0x1b; // 1_1011
      case Arm7TdmiProcessorMode.system:
        return 0x1f; // 1_1111
      default:
        throw ArgumentError.notNull();
    }
  }
}
