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


class MemoryTF(Dashboard.Module):
    '''Show the Thumbfuck memories.'''

    # from defs.i
    _SRAM_BASE = 0x20000000
    _SRAM_SIZE = 0x00004000
    _SRAM_END = _SRAM_BASE + _SRAM_SIZE

    # from main.s
    _REG_PP = '$r2'
    _REG_DP = '$r3'
    _REG_EOP = '$r11'

    # from main.s
    _EXECUTORS = {
        'Exec_dm_inc': '+',
        'Exec_dm_dec': '-',
        'Exec_dp_inc': '>',
        'Exec_dp_dec': '<',
        'Exec_pp_jfz': '[',
        'Exec_pp_jbn': ']',
        'Exec_dm_out': '.',
        'Exec_dm_inb': ',',
        'Main_prompt': '#',
    }

    def __init__(self):
        self._regs_str = '   '.join(
            f' {ansi(reg, R.style_low)} {{}}' for reg in ('EOP', 'PP', 'DP')
        )
        self._last_eop = None
        self._last_pp = None
        self._last_dp = None
        self._exec = None

    def label(self):
        return 'Memory-TF'

    def lines(self, term_width, term_height, style_changed):
        if not gdb.selected_thread().is_stopped():
            return []
        if not self._exec:
            self._init_executors()
        eop = gdb.parse_and_eval(self._REG_EOP)
        pp = gdb.parse_and_eval(self._REG_PP)
        dp = gdb.parse_and_eval(self._REG_DP)
        out = [self._line_regs(eop, pp, dp)]
        if not (self._SRAM_BASE <= eop < self._SRAM_END):
            eop = gdb.Value(self._SRAM_BASE)
        out.append(divider(term_width, 'program'))
        out.extend(self._lines_progmem(eop, pp))
        out.append(divider(term_width, 'data'))
        out.extend(self._lines_datamem(eop, dp))
        return out

    def _line_regs(self, eop, pp, dp):
        if self._last_eop is None:
            self._last_eop = eop
            self._last_pp = pp
            self._last_dp = dp
        eop_str = eop.format_string(format="z")
        if self._last_eop != eop:
            eop_str = ansi(eop_str, R.style_selected_1)
            self._last_eop = eop
        pp_str = pp.format_string(format="z")
        if self._last_pp != pp:
            pp_str = ansi(pp_str, R.style_selected_1)
            self._last_pp = pp
        dp_str = dp.format_string(format="z")
        if self._last_dp != dp:
            dp_str = ansi(dp_str, R.style_selected_1)
            self._last_dp = dp
        return self._regs_str.format(eop_str, pp_str, dp_str)

    def _lines_progmem(self, eop, pp):  # TODO: moving window for long programs
        if (length := eop - self._SRAM_BASE) == 0:
            return [' no program loaded (or invalid EOP)']
        err_msg, pm = self._fetch_sram(self._SRAM_BASE, length)
        if err_msg:
            return [err_msg]
        pm = [
            pm[i][0] | pm[i+1][0] << 8 | pm[i+2][0] << 16 | pm[i+3][0] << 24
            for i in range(0, len(pm), 4)
        ]
        per_line = 8  # TODO: config or term_width
        addr = self._SRAM_BASE
        out = []
        for i in range(0, len(pm), per_line):
            row_addr = addr
            hex_row = []
            op_row = ''
            for j in range(per_line):
                rel = i + j
                data = pm[rel]
                hex_str = f'{data:08x}'
                if addr == pp:
                    hex_str = ansi(hex_str, R.style_selected_1)
                hex_row.append(hex_str)
                if op_chr := self._exec.get(data):
                    op_str = op_chr
                    if addr == pp:
                        op_str = ansi(op_str, R.style_selected_1)
                    op_row += op_str
                elif addr == pp:
                    op_row += ansi('?', R.style_selected_1)
                else:
                    op_row += ' '
                addr += 4
                if addr == eop:
                    break
            if pad := per_line - j - 1:
                hex_row.extend(['        '] * pad)
            addr_str = ansi(f'0x{row_addr:08x}', R.style_low)
            out.append(f' {addr_str}  {" ".join(hex_row)}  {op_row}')
        return out

    def _lines_datamem(self, eop, dp):  # TODO: moving window
        length = 256  # TODO: config
        err_msg, dm = self._fetch_sram(eop, length)
        if err_msg:
            return [err_msg]
        dm = [dm[i][0] for i in range(len(dm))]
        per_line = 16  # TODO: config or term_width
        addr = int(eop)
        out = []
        for i in range(0, len(dm), per_line):
            row_addr = addr
            hex_row = []
            chr_row = ''
            for j in range(per_line):
                rel = i + j
                data = dm[rel]
                hex_str = f'{data:02x}'
                if addr == dp:
                    hex_str = ansi(hex_str, R.style_selected_1)
                hex_row.append(hex_str)
                if 0x20 <= data < 0x7F:
                    chr_str = chr(data)
                    if addr == dp:
                        chr_str = ansi(chr_str, R.style_selected_1)
                    chr_row += chr_str
                else:
                    chr_row += ansi('.', R.style_selected_2 if addr == dp else R.style_low)
                addr += 1
            addr_str = ansi(f'0x{row_addr:08x}', R.style_low)
            out.append(f' {addr_str}  {" ".join(hex_row)}  {chr_row}')
        return out

    def _init_executors(self):
        self._exec = {}
        for label, op_chr in self._EXECUTORS.items():
            try:
                addr = gdb.parse_and_eval(label).address
            except gdb.error:
                pass
            else:
                self._exec[int(addr)] = op_chr

    @staticmethod
    def _fetch_sram(address, length):
        # fetch SRAM content
        try:
            inferior = gdb.selected_inferior()
            sram = inferior.read_memory(address, length)
        except gdb.error as e:
            msg = f'Could not read {length} bytes from SRAM: {e}'
            return ansi(msg, R.style_error), None
        return None, sram


# not the "official" way to add gdb-dashboard modules
dashboard.modules.append(Dashboard.ModuleInfo(dashboard, RegistersM0))
dashboard.modules.append(Dashboard.ModuleInfo(dashboard, MemoryTF))

end

define tf-start
    target extended-remote:3333
    dashboard -layout assembly source breakpoints registersm0 memorytf
    monitor reset halt
    break *0x08000388
    dashboard
end

define tf-reload
    file thumbfuck.elf
    load
    monitor reset halt
    dashboard
end
