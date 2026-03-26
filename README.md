# FemtoCompiler 🛣️

[![CI](https://github.com/wookay/FemtoCompiler.jl/actions/workflows/actions.yml/badge.svg)](https://github.com/wookay/FemtoCompiler.jl/actions/workflows/actions.yml)

* Doors
```
alias jd="julia -i --trace-compile-timing --trace-compile=stderr --compiled-modules=yes -e 'using Doors; serve(; into=Main)'  "
alias jc="julia    --trace-compile-timing --trace-compile=stderr --compiled-modules=yes -e 'using Doors; runargs()'  "
```

### repositories
 - FemtoCompiler 🛣️  https://github.com/wookay/FemtoCompiler.jl
 - Doors 🚪  https://github.com/wookay/Doors.jl
 - TestCompiler 🚗  https://github.com/wookay/TestCompiler.jl
 - TestJuliaLowering 📉  https://github.com/wookay/TestJuliaLowering.jl
 - TestStdlibs 🏫  https://github.com/wookay/TestStdlibs.jl
 - TestLLM 💬  https://github.com/wookay/TestLLM.jl
 - TestPkgs 📦  https://github.com/wookay/TestPkgs.jl
