source ./tools/gdb-dashboard/.gdbinit

define tf-start
    target extended-remote:3333
    dashboard -layout assembly source breakpoints registers memory
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
