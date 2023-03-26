source ./tools/gdb-dashboard/.gdbinit

python

class RegistersM0(Dashboard.Module):
    '''Show the Cortex-M0 registers and their values.'''

    REG_ROWS = (  # register names (gdb expressions)
        ('$r0', '$r8', '$xpsr'),
        ('$r1', '$r9'),
        ('$r2', '$r10', '$msp'),
        ('$r3', '$r11', '$psp'),
        ('$r4', '$r12'),
        ('$r5', '$sp', '$primask'),
        ('$r6', '$lr', '$control'),
        ('$r7', '$pc'),
    )

    XPSR_BITS = (
        ('N', 1 << 31), ('Z', 1 << 30), ('C', 1 << 29), ('V', 1 << 28),  # APSR
        ('T', 1 << 24),  # EPSR
    )
    IPSR_MASK = 0x0000003F
    PRIMASK_PM_BIT = 0x00000001
    CONTROL_SPSEL_BIT = 0x00000002

    class Reg:
        def __init__(self, name, conv=None):
            self._name = ansi(name, R.style_low)
            self._conv = conv or self.conv_int
            self._value = None
            self._hex_str = 'n/a'
            self._conv_str = 'n/a'

        def format(self, value):
            if self._value == value:
                hex_str = self._hex_str
            else:
                self._value = value
                self._hex_str = value.format_string(format='z')
                self._conv_str = self._conv(value)
                hex_str = ansi(self._hex_str, R.style_selected_1)
            return f'{self._name} {hex_str} {self._conv_str}'

        @staticmethod
        def conv_int(value):
            return f'{value.format_string(format="d"):12}'

        @staticmethod
        def conv_xpsr(value):
            bits = [f'{name}={1 if value & mask else 0}' for (name, mask) in RegistersM0.XPSR_BITS]
            return f'{" ".join(bits)} ipsr={value & RegistersM0.IPSR_MASK}'

        @staticmethod
        def conv_primask(value):
            return f'      PM={1 if value & RegistersM0.PRIMASK_PM_BIT else 0}'

        @staticmethod
        def conv_control(value):
            return f'      SPSEL={1 if value & RegistersM0.CONTROL_SPSEL_BIT else 0}'

    def __init__(self):
        self._regs = {
            '$r0':   self.Reg(' r0'),
            '$r1':   self.Reg(' r1'),
            '$r2':   self.Reg(' r2'),
            '$r3':   self.Reg(' r3'),
            '$r4':   self.Reg(' r4'),
            '$r5':   self.Reg(' r5'),
            '$r6':   self.Reg(' r6'),
            '$r7':   self.Reg(' r7'),
            '$r8':   self.Reg(' r8'),
            '$r9':   self.Reg(' r9'),
            '$r10':  self.Reg('r10'),
            '$r11':  self.Reg('r11'),
            '$r12':  self.Reg('r12'),
            '$sp':   self.Reg('r13', lambda _: '(sp)     '),
            '$lr':   self.Reg('r14', lambda _: '(lr)     '),
            '$pc':   self.Reg('r15', lambda _: '(pc)'),
            '$xpsr': self.Reg('xpsr', self.Reg.conv_xpsr),
            '$msp':  self.Reg(' msp', lambda _: ''),
            '$psp':  self.Reg(' psp', lambda _: ''),
            '$primask': self.Reg('primask', self.Reg.conv_primask),
            '$control': self.Reg('control', self.Reg.conv_control),
        }

    def label(self):
        return 'Registers-M0'

    def lines(self, term_width, term_height, style_changed):
        # skip if the current thread is not stopped
        if not gdb.selected_thread().is_stopped():
            return []
        out = []
        for row_def in self.REG_ROWS:
            regs = []
            for reg_name in row_def:
                value = gdb.parse_and_eval(reg_name)
                regs.append(self._regs[reg_name].format(value))
            out.append('  '.join(regs))
        return out

# not the "official" way to add gdb-dashboard modules
dashboard.modules.append(Dashboard.ModuleInfo(dashboard, RegistersM0))

end

define tf-start
    target extended-remote:3333
    dashboard -layout assembly source breakpoints registersm0 memory
    monitor reset halt
    break *0x08000388
    dashboard memory watch 0x20000000 256
    dashboard
end

define tf-reload
    file thumbfuck.elf
    load
    monitor reset halt
    dashboard
end
