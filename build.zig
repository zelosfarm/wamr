const std = @import("std");
const builtin = @import("builtin");

const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const cpu_arch = target.cpu_arch orelse builtin.cpu.arch;
    const os_tag = target.os_tag orelse builtin.os.tag;

    const build_interp = b.option(bool, "WAMR_BUILD_INTERP", "Enable interpreter") orelse true;
    const build_fast_interp = b.option(bool, "WAMR_BUILD_FAST_INTERP", "Enable fast interpreter") orelse false;
    const build_aot = b.option(bool, "WAMR_BUILD_AOT", "Enable AOT") orelse true;
    const build_jit = b.option(bool, "WAMR_BUILD_JIT", "Enable JIT") orelse false;
    const build_fast_jit = b.option(bool, "WAMR_BUILD_FAST_JIT", "Enable fast JIT") orelse false;
    const build_libc_builtin = b.option(bool, "WAMR_BUILD_LIBC_BUILTIN", "Enable libc builtin support") orelse true;
    const build_libc_wasi = b.option(bool, "WAMR_BUILD_LIBC_WASI", "Enable libc wasi support") orelse false;
    const build_libc_uvwasi = b.option(bool, "WAMR_BUILD_LIBC_UVWASI", "Enable libc uvwasi support") orelse false;

    const build_fast_mini_loader = b.option(bool, "WAMR_BUILD_MINI_LOADER", "Enable mini loader") orelse false;
    const build_multi_module = b.option(bool, "WAMR_BUILD_MULTI_MODULE", "Enable multiple modules") orelse false;
    const build_lib_pthread = b.option(bool, "WAMR_BUILD_LIB_PTHREAD", "Enable pthread library") orelse false;
    const build_lib_pthread_semaphore = b.option(bool, "WAMR_BUILD_LIB_PTHREAD_SEMAPHORE", "Enable pthread library") orelse false;
    const build_lib_wasi_thread = b.option(bool, "WAMR_BUILD_LIB_WASI_THREADS", "Enable wasi threads library") orelse false;
    const build_simd = b.option(bool, "WAMR_BUILD_SIMD", "Enable SIMD") orelse true;
    const build_ref_types = b.option(bool, "WAMR_BUILD_REF_TYPES", "Enable reference types") orelse false;
    const build_shared_memory = b.option(bool, "WAMR_BUILD_SHARED_MEMORY", "Enable shared memory") orelse false;
    const build_bulk_memory = b.option(bool, "WAMR_BUILD_BULK_MEMORY", "Enable bulk memory") orelse true;

    const disable_hw_bound_check = b.option(bool, "WAMR_DISABLE_HW_BOUND_CHECK", "Disable Hardware boundary check") orelse false;
    const disable_stack_hw_bound_check = b.option(bool, "WAMR_DISABLE_STACK_HW_BOUND_CHECK", "Hardware boundary check for native stack") orelse false;

    if (target.isWindows() and build_libc_wasi and !build_libc_uvwasi) {
        @panic("libc wasi is not supported on this target, try libc uvwasi instead");
    }

    if (build_jit or build_fast_jit) {
        if (!build_interp) {
            @panic("Interpreter must be enabled for JIT");
        }
        if (build_fast_interp) {
            @panic("Fast interpreter must not be enabled for JIT");
        }
        if (!build_aot) {
            @panic("AOT must be enabled for JIT");
        }
    }

    if (build_fast_jit) {
        @panic("Fast JIT is not supported yet");
    }

    if (build_lib_pthread_semaphore and !build_lib_pthread) {
        @panic("Lib pthread must be enabled for semaphore");
    }

    const vmlib = b.addStaticLibrary(.{
        .name = "vmlib",
        .target = target,
        .optimize = optimize,
    });
    vmlib.want_lto = false;
    vmlib.disable_sanitize_c = true;
    if (optimize == .ReleaseFast)
        vmlib.strip = true;
    vmlib.linkLibC();
    vmlib.linkLibCpp();

    if (target.isWindows()) {
        vmlib.linkLibrary(b.dependency("winpthreads", .{
            .target = target,
            .optimize = optimize,
        }).artifact("winpthreads"));
    }

    if (build_aot) {
        vmlib.addIncludePath(.{ .path = "C:/Development/zelosfarm_old/llvm-project-llvmorg-15.0.7/llvm/include" });
        vmlib.addIncludePath(.{ .path = "C:/Development/zelosfarm_old/llvm-project-llvmorg-15.0.7/llvm/build-debug/include" });
        vmlib.addLibraryPath(.{ .path = "C:/Development/zelosfarm_old/llvm-project-llvmorg-15.0.7/llvm/build-debug/lib" });
        vmlib.linkSystemLibrary("LLVMWindowsManifest");
        vmlib.linkSystemLibrary("LLVMWindowsDriver");
        vmlib.linkSystemLibrary("LLVMXRay");
        vmlib.linkSystemLibrary("LLVMLibDriver");
        vmlib.linkSystemLibrary("LLVMDlltoolDriver");
        vmlib.linkSystemLibrary("LLVMCoverage");
        vmlib.linkSystemLibrary("LLVMLineEditor");
        vmlib.linkSystemLibrary("LLVMX86TargetMCA");
        vmlib.linkSystemLibrary("LLVMX86Disassembler");
        vmlib.linkSystemLibrary("LLVMX86AsmParser");
        vmlib.linkSystemLibrary("LLVMX86CodeGen");
        vmlib.linkSystemLibrary("LLVMX86Desc");
        vmlib.linkSystemLibrary("LLVMX86Info");
        vmlib.linkSystemLibrary("LLVMOrcJIT");
        vmlib.linkSystemLibrary("LLVMMCJIT");
        vmlib.linkSystemLibrary("LLVMJITLink");
        vmlib.linkSystemLibrary("LLVMInterpreter");
        vmlib.linkSystemLibrary("LLVMExecutionEngine");
        vmlib.linkSystemLibrary("LLVMRuntimeDyld");
        vmlib.linkSystemLibrary("LLVMOrcTargetProcess");
        vmlib.linkSystemLibrary("LLVMOrcShared");
        vmlib.linkSystemLibrary("LLVMDWP");
        vmlib.linkSystemLibrary("LLVMDebugInfoGSYM");
        vmlib.linkSystemLibrary("LLVMOption");
        vmlib.linkSystemLibrary("LLVMObjectYAML");
        vmlib.linkSystemLibrary("LLVMObjCopy");
        vmlib.linkSystemLibrary("LLVMMCA");
        vmlib.linkSystemLibrary("LLVMMCDisassembler");
        vmlib.linkSystemLibrary("LLVMLTO");
        vmlib.linkSystemLibrary("LLVMPasses");
        vmlib.linkSystemLibrary("LLVMCFGuard");
        vmlib.linkSystemLibrary("LLVMCoroutines");
        vmlib.linkSystemLibrary("LLVMObjCARCOpts");
        vmlib.linkSystemLibrary("LLVMipo");
        vmlib.linkSystemLibrary("LLVMVectorize");
        vmlib.linkSystemLibrary("LLVMLinker");
        vmlib.linkSystemLibrary("LLVMInstrumentation");
        vmlib.linkSystemLibrary("LLVMFrontendOpenMP");
        vmlib.linkSystemLibrary("LLVMFrontendOpenACC");
        vmlib.linkSystemLibrary("LLVMExtensions");
        vmlib.linkSystemLibrary("LLVMDWARFLinker");
        vmlib.linkSystemLibrary("LLVMGlobalISel");
        vmlib.linkSystemLibrary("LLVMMIRParser");
        vmlib.linkSystemLibrary("LLVMAsmPrinter");
        vmlib.linkSystemLibrary("LLVMSelectionDAG");
        vmlib.linkSystemLibrary("LLVMCodeGen");
        vmlib.linkSystemLibrary("LLVMIRReader");
        vmlib.linkSystemLibrary("LLVMAsmParser");
        vmlib.linkSystemLibrary("LLVMInterfaceStub");
        vmlib.linkSystemLibrary("LLVMFileCheck");
        vmlib.linkSystemLibrary("LLVMFuzzMutate");
        vmlib.linkSystemLibrary("LLVMTarget");
        vmlib.linkSystemLibrary("LLVMScalarOpts");
        vmlib.linkSystemLibrary("LLVMInstCombine");
        vmlib.linkSystemLibrary("LLVMAggressiveInstCombine");
        vmlib.linkSystemLibrary("LLVMTransformUtils");
        vmlib.linkSystemLibrary("LLVMBitWriter");
        vmlib.linkSystemLibrary("LLVMAnalysis");
        vmlib.linkSystemLibrary("LLVMProfileData");
        vmlib.linkSystemLibrary("LLVMSymbolize");
        vmlib.linkSystemLibrary("LLVMDebugInfoPDB");
        vmlib.linkSystemLibrary("LLVMDebugInfoMSF");
        vmlib.linkSystemLibrary("LLVMDebugInfoDWARF");
        vmlib.linkSystemLibrary("LLVMObject");
        vmlib.linkSystemLibrary("LLVMTextAPI");
        vmlib.linkSystemLibrary("LLVMMCParser");
        vmlib.linkSystemLibrary("LLVMMC");
        vmlib.linkSystemLibrary("LLVMDebugInfoCodeView");
        vmlib.linkSystemLibrary("LLVMBitReader");
        vmlib.linkSystemLibrary("LLVMFuzzerCLI");
        vmlib.linkSystemLibrary("LLVMCore");
        vmlib.linkSystemLibrary("LLVMRemarks");
        vmlib.linkSystemLibrary("LLVMBitstreamReader");
        vmlib.linkSystemLibrary("LLVMBinaryFormat");
        vmlib.linkSystemLibrary("LLVMTableGen");
        vmlib.linkSystemLibrary("LLVMSupport");
        vmlib.linkSystemLibrary("LLVMDemangle");
    }

    vmlib.addIncludePath(.{ .path = "core/iwasm/include" });

    var vmlib_flags = ArrayList([]const u8).init(b.allocator);
    var vmlib_sources = ArrayList([]const u8).init(b.allocator);
    defer vmlib_flags.deinit();
    defer vmlib_sources.deinit();

    // vmlib_flags.append("-DWASM_DISABLE_WRITE_GS_BASE=1") catch @panic("OOM");

    if (disable_hw_bound_check) {
        vmlib_flags.append("-DWASM_DISABLE_HW_BOUND_CHECK=1") catch @panic("OOM");
        vmlib_flags.append("-DWASM_DISABLE_STACK_HW_BOUND_CHECK=1") catch @panic("OOM");
    } else {
        vmlib_flags.append("-DWASM_DISABLE_HW_BOUND_CHECK=0") catch @panic("OOM");
        if (disable_stack_hw_bound_check) {
            vmlib_flags.append("-DWASM_DISABLE_STACK_HW_BOUND_CHECK=1") catch @panic("OOM");
        } else {
            vmlib_flags.append("-DWASM_DISABLE_STACK_HW_BOUND_CHECK=0") catch @panic("OOM");
        }
        if (target.isWindows()) {
            vmlib.linkLibrary(b.dependency("zycore", .{
                .target = target,
                .optimize = optimize,
            }).artifact("zycore"));
            vmlib.linkLibrary(b.dependency("zydis", .{
                .target = target,
                .optimize = optimize,
            }).artifact("zydis"));
        }
    }

    if (build_interp or build_fast_interp) {
        vmlib.addIncludePath(.{ .path = "core/iwasm/interpreter" });

        vmlib_sources.append("core/iwasm/interpreter/wasm_runtime.c") catch @panic("OOM");
        if (build_fast_mini_loader) {
            vmlib_flags.append("-DWASM_ENABLE_MINI_LOADER=1") catch @panic("OOM");

            vmlib_sources.append("core/iwasm/interpreter/wasm_mini_loader.c") catch @panic("OOM");
        } else {
            vmlib_flags.append("-DWASM_ENABLE_MINI_LOADER=0") catch @panic("OOM");

            vmlib_sources.append("core/iwasm/interpreter/wasm_loader.c") catch @panic("OOM");
        }

        if (build_fast_interp) {
            vmlib_flags.append("-DWASM_ENABLE_FAST_INTERP=1") catch @panic("OOM");
            vmlib_flags.append("-DWASM_ENABLE_INTERP=0") catch @panic("OOM");

            vmlib_sources.append("core/iwasm/interpreter/wasm_interp_fast.c") catch @panic("OOM");
        } else if (build_interp) {
            vmlib_flags.append("-DWASM_ENABLE_FAST_INTERP=0") catch @panic("OOM");
            vmlib_flags.append("-DWASM_ENABLE_INTERP=1") catch @panic("OOM");

            vmlib_sources.append("core/iwasm/interpreter/wasm_interp_classic.c") catch @panic("OOM");
        }
    }

    if (build_aot) {
        vmlib_flags.append("-DWASM_ENABLE_AOT=1") catch @panic("OOM");
        vmlib_flags.append("-DWASM_ENABLE_WAMR_COMPILER=1") catch @panic("OOM");

        vmlib.addIncludePath(.{ .path = "core/iwasm/aot" });
        vmlib_sources.append("core/iwasm/aot/aot_intrinsic.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/aot/aot_loader.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/aot/aot_runtime.c") catch @panic("OOM");
        switch (cpu_arch) {
            .aarch64 => vmlib_sources.append("core/iwasm/aot/arch/aot_reloc_aarch64.c") catch @panic("OOM"),
            .x86_64 => vmlib_sources.append("core/iwasm/aot/arch/aot_reloc_x86_64.c") catch @panic("OOM"),
            else => @panic("unsupported arch"),
        }

        if (optimize == .Debug) {
            // vmlib_flags.append("-DWASM_ENABLE_DEBUG_AOT=1") catch @panic("OOM");
            // vmlib.addIncludePath(.{ .path = "C:/Development/zelosfarm/llvm-project-llvmorg-15.0.7/lldb/include" });

            // vmlib_sources.append("core/iwasm/aot/debug/elf_parser.c") catch @panic("OOM");
            // vmlib_sources.append("core/iwasm/aot/debug/jit_debug.c") catch @panic("OOM");
            // vmlib_sources.append("core/iwasm/compilation/debug/dwarf_extractor.cpp") catch @panic("OOM");
        }

        vmlib.addIncludePath(.{ .path = "core/iwasm/compilation" });
        vmlib_sources.append("core/iwasm/compilation/aot_compiler.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_aot_file.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_compare.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_const.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_control.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_conversion.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_exception.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_function.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_memory.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_numberic.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_parametric.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_table.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_emit_variable.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_llvm_extra.cpp") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_llvm_extra2.cpp") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_llvm.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_orc_extra.cpp") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot_orc_extra2.cpp") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/compilation/aot.c") catch @panic("OOM");
        if (build_simd) {
            vmlib.addIncludePath(.{ .path = "core/iwasm/compilation/simd" });

            vmlib_sources.append("core/iwasm/compilation/simd/simd_access_lanes.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_bit_shifts.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_bitmask_extracts.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_bitwise_ops.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_bool_reductions.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_common.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_comparisons.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_construct_values.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_conversions.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_floating_point.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_int_arith.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_load_store.c") catch @panic("OOM");
            vmlib_sources.append("core/iwasm/compilation/simd/simd_sat_int_arith.c") catch @panic("OOM");
        }
    }

    if (build_libc_builtin) {
        vmlib_flags.append("-DWASM_ENABLE_LIBC_BUILTIN=1") catch @panic("OOM");

        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/libc-builtin" });
        vmlib_sources.append("core/iwasm/libraries/libc-builtin/libc_builtin_wrapper.c") catch @panic("OOM");
    }

    if (build_libc_uvwasi) {
        vmlib_flags.append("-DWASM_ENABLE_LIBC_WASI=1") catch @panic("OOM");
        vmlib_flags.append("-DWASM_ENABLE_UVWASI=1") catch @panic("OOM");
        vmlib_flags.append("-DWASM_ENABLE_MODULE_INST_CONTEXT=1") catch @panic("OOM");

        vmlib_sources.append("core/iwasm/libraries/libc-uvwasi/libc_uvwasi_wrapper.c") catch @panic("OOM");

        vmlib.linkLibrary(b.dependency("uv", .{
            .target = target,
            .optimize = optimize,
        }).artifact("uv"));
        vmlib.linkLibrary(b.dependency("uvwasi", .{
            .target = target,
            .optimize = optimize,
        }).artifact("uvwasi"));
    } else if (build_libc_wasi) {
        if (target.isWindows()) {
            @panic("WAMR_BUILD_LIBC_WASI=true is not supported on windows, use WAMR_BUILD_LIBC_UVWASI instead");
        }

        vmlib_flags.append("-DWASM_ENABLE_LIBC_WASI=1") catch @panic("OOM");
        vmlib_flags.append("-DWASM_ENABLE_MODULE_INST_CONTEXT=1") catch @panic("OOM");

        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/libc-wasi" });
        vmlib_sources.append("core/iwasm/libraries/libc-wasi/libc_wasi_wrapper.c") catch @panic("OOM");

        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/include" });
        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src" });
        vmlib_sources.append("core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src/blocking_op.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src/posix.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src/random.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src/str.c") catch @panic("OOM");
    }

    if (build_lib_pthread) {
        vmlib_flags.append("-DWASM_ENABLE_LIB_PTHREAD=1") catch @panic("OOM");
        if (build_lib_pthread_semaphore) {
            vmlib_flags.append("-DWASM_ENABLE_LIB_PTHREAD_SEMAPHORE=1") catch @panic("OOM");
        }

        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/lib-pthread" });
        vmlib_sources.append("core/iwasm/libraries/lib-pthread/lib-pthread_wrapper.c") catch @panic("OOM");
    }

    if (build_lib_wasi_thread) {
        vmlib_flags.append("-DWASM_ENABLE_LIB_WASI_THREADS=1") catch @panic("OOM");
        vmlib_flags.append("-DWASM_ENABLE_HEAP_AUX_STACK_ALLOCATION=1") catch @panic("OOM");

        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/lib-wasi-threads" });
        vmlib_sources.append("core/iwasm/libraries/lib-wasi-threads/lib_wasi_threads_wrapper.c") catch @panic("OOM");
        vmlib_sources.append("core/iwasm/libraries/lib-wasi-threads/tid_allocator.c") catch @panic("OOM");

        vmlib_flags.append("-DWASM_ENABLE_THREAD_MGR=1") catch @panic("OOM");

        vmlib.addIncludePath(.{ .path = "core/iwasm/libraries/thread-mgr" });
        vmlib_sources.append("core/iwasm/libraries/thread-mgr/thread_manager.c") catch @panic("OOM");
    }

    switch (cpu_arch) {
        .aarch64 => vmlib_flags.append("-DBUILD_TARGET_AARCH64") catch @panic("OOM"),
        .x86_64 => vmlib_flags.append("-DBUILD_TARGET_X86_64") catch @panic("OOM"),
        else => @panic("unsupported arch"),
    }

    if (optimize == .Debug) {
        vmlib_flags.append("-DBH_DEBUG=1") catch @panic("OOM");
        vmlib_flags.append("-DBH_ENABLE_TRACE_MMAP=1") catch @panic("OOM");
    }

    vmlib.addIncludePath(.{ .path = "core/shared/platform/include" });
    switch (os_tag) {
        .windows => {
            vmlib_flags.append("-DBH_PLATFORM_WINDOWS") catch @panic("OOM");
            vmlib_flags.append("-DHAVE_STRUCT_TIMESPEC") catch @panic("OOM");
            vmlib_flags.append("-D_WINSOCK_DEPRECATED_NO_WARNINGS") catch @panic("OOM");

            vmlib.addIncludePath(.{ .path = "core/shared/platform/windows" });

            vmlib_sources.append("core/shared/platform/windows/platform_init.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/windows/win_atomic.cpp") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/windows/win_malloc.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/windows/win_memmap.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/windows/win_socket.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/windows/win_thread.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/windows/win_time.c") catch @panic("OOM");
        },
        .linux => {
            vmlib_flags.append("-DBH_PLATFORM_LINUX") catch @panic("OOM");
            vmlib.addIncludePath(.{ .path = "core/shared/platform/linux" });
            vmlib.addIncludePath(.{ .path = "core/shared/platform/common/libc-util" });

            vmlib_sources.append("core/shared/platform/linux/platform_init.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_blocking_op.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_clock.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_file.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_malloc.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_memmap.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_sleep.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_socket.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_thread.c") catch @panic("OOM");
            vmlib_sources.append("core/shared/platform/common/posix/posix_time.c") catch @panic("OOM");

            vmlib_sources.append("core/shared/platform/common/libc-util/libc_errno.c") catch @panic("OOM");
        },
        else => @panic("unsupported os"),
    }

    vmlib_flags.append("-DBH_MALLOC=wasm_runtime_malloc") catch @panic("OOM");
    vmlib_flags.append("-DBH_FREE=wasm_runtime_free") catch @panic("OOM");

    vmlib.addIncludePath(.{ .path = "core/iwasm/common" });
    vmlib_sources.append("core/iwasm/common/wasm_application.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_blocking_op.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_c_api.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_exec_env.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_memory.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_native.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_runtime_common.c") catch @panic("OOM");
    vmlib_sources.append("core/iwasm/common/wasm_shared_memory.c") catch @panic("OOM");
    // switch (os_tag) {
    //     .windows => {
    //         if (build_simd) {
    //             vmlib_sources.append("core/iwasm/common/arch/invokeNative_mingw_x64_simd.s") catch @panic("OOM");
    //         } else {
    //             vmlib_sources.append("core/iwasm/common/arch/invokeNative_mingw_x64.s") catch @panic("OOM");
    //         }
    //     },
    //     else => {
    //         if (build_simd) {
    //             vmlib_sources.append("core/iwasm/common/arch/invokeNative_em64_simd.s") catch @panic("OOM");
    //         } else {
    //             vmlib_sources.append("core/iwasm/common/arch/invokeNative_em64.s") catch @panic("OOM");
    //         }
    //     },
    // }
    // vmlib_sources.append("core/iwasm/common/arch/invokeNative_general.c") catch @panic("OOM");
    if (build_simd) {
        vmlib_sources.append("core/iwasm/common/arch/invokeNative_mingw_x64_simd.s") catch @panic("OOM");
    } else {
        vmlib_sources.append("core/iwasm/common/arch/invokeNative_mingw_x64.s") catch @panic("OOM");
    }

    vmlib.addIncludePath(.{ .path = "core/shared/utils" });
    vmlib_sources.append("core/shared/utils/bh_assert.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_common.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_hashmap.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_list.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_log.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_queue.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_vector.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/runtime_timer.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/utils/bh_bitmap.c") catch @panic("OOM");

    if (build_multi_module) {
        vmlib_flags.append("-DWASM_ENABLE_MULTI_MODULE=1") catch @panic("OOM");
    } else {
        vmlib_flags.append("-DWASM_ENABLE_MULTI_MODULE=0") catch @panic("OOM");
    }

    if (build_simd) {
        vmlib_flags.append("-DWASM_ENABLE_SIMD=1") catch @panic("OOM");
    }

    if (build_ref_types) {
        vmlib_flags.append("-DWASM_ENABLE_REF_TYPES=1") catch @panic("OOM");
    }
    if (build_shared_memory) {
        vmlib_flags.append("-DWASM_ENABLE_SHARED_MEMORY=1") catch @panic("OOM");
    } else {
        vmlib_flags.append("-DWASM_ENABLE_SHARED_MEMORY=0") catch @panic("OOM");
    }
    if (build_bulk_memory) {
        vmlib_flags.append("-DWASM_ENABLE_BULK_MEMORY=1") catch @panic("OOM");
    } else {
        vmlib_flags.append("-DWASM_ENABLE_BULK_MEMORY=0") catch @panic("OOM");
    }
    vmlib_flags.append("-DWASM_CONFIGURABLE_BOUNDS_CHECKS=1") catch @panic("OOM");
    vmlib_flags.append("-DWASM_DISABLE_STACK_HW_BOUND_CHECK=0") catch @panic("OOM");

    vmlib.addIncludePath(.{ .path = "core/shared/mem-alloc" });
    vmlib_sources.append("core/shared/mem-alloc/mem_alloc.c") catch @panic("OOM");

    vmlib.addIncludePath(.{ .path = "core/shared/mem-alloc/ems" });
    vmlib_sources.append("core/shared/mem-alloc/ems/ems_alloc.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/mem-alloc/ems/ems_hmu.c") catch @panic("OOM");
    vmlib_sources.append("core/shared/mem-alloc/ems/ems_kfc.c") catch @panic("OOM");

    vmlib.addCSourceFiles(.{ .files = vmlib_sources.items, .flags = vmlib_flags.items });

    vmlib.installHeadersDirectory("core/iwasm/include", "");
    b.installArtifact(vmlib);

    const iwasm = b.addExecutable(.{
        .name = "iwasm",
        .target = target,
        .optimize = optimize,
    });
    iwasm.want_lto = false;
    iwasm.disable_sanitize_c = true;
    if (optimize == .ReleaseFast)
        vmlib.strip = true;
    iwasm.step.dependOn(&vmlib.step);
    iwasm.linkLibC();
    iwasm.addLibraryPath(.{ .path = "C:/Development/zelosfarm_old/llvm-project-llvmorg-15.0.7/llvm/build-debug/lib" });
    iwasm.linkLibrary(vmlib);
    // if (!disable_hw_bound_check) {
    //     iwasm.linkLibrary(b.dependency("zycore", .{
    //         .target = target,
    //         .optimize = optimize,
    //     }).artifact("zycore"));
    //     iwasm.linkLibrary(b.dependency("zydis", .{
    //         .target = target,
    //         .optimize = optimize,
    //     }).artifact("zydis"));
    // }

    // if (target.isWindows()) {
    //     iwasm.linkLibrary(b.dependency("winpthreads", .{
    //         .target = target,
    //         .optimize = optimize,
    //     }).artifact("winpthreads"));
    // }

    // if (build_libc_uvwasi) {
    //     iwasm.linkLibrary(b.dependency("uv", .{
    //         .target = target,
    //         .optimize = optimize,
    //     }).artifact("uv"));
    //     iwasm.linkLibrary(b.dependency("uvwasi", .{
    //         .target = target,
    //         .optimize = optimize,
    //     }).artifact("uvwasi"));
    // }
    iwasm.addIncludePath(.{ .path = "core/shared/platform/include" });

    var iwasm_flags = ArrayList([]const u8).init(b.allocator);
    var iwasm_sources = ArrayList([]const u8).init(b.allocator);
    defer iwasm_flags.deinit();
    defer iwasm_sources.deinit();

    switch (os_tag) {
        .windows => {
            iwasm.addIncludePath(.{ .path = "core/shared/platform/windows" });
            iwasm_flags.append("-DCOMPILING_WASM_RUNTIME_API=1") catch @panic("OOM");
            iwasm_sources.append("product-mini/platforms/windows/main.c") catch @panic("OOM");

            iwasm.linkSystemLibrary("Ole32");
            iwasm.linkSystemLibrary("Dbghelp");
            iwasm.linkSystemLibrary("iphlpapi");
            iwasm.linkSystemLibrary("psapi");
            iwasm.linkSystemLibrary("userenv");
            iwasm.linkSystemLibrary("ws2_32");
        },
        .linux => {
            iwasm.addIncludePath(.{ .path = "core/shared/platform/linux" });
            iwasm_flags.append("-DCOMPILING_WASM_RUNTIME_API=1") catch @panic("OOM");
            iwasm_sources.append("product-mini/platforms/linux/main.c") catch @panic("OOM");
        },
        else => @panic("unsupported os"),
    }
    iwasm.addIncludePath(.{ .path = "core/iwasm/include" });
    iwasm.addIncludePath(.{ .path = "core/shared/utils" });
    iwasm.addIncludePath(.{ .path = "core/shared/utils/uncommon" });

    iwasm_sources.append("core/shared/utils/uncommon/bh_getopt.c") catch @panic("OOM");
    iwasm_sources.append("core/shared/utils/uncommon/bh_read_file.c") catch @panic("OOM");

    iwasm_flags.appendSlice(vmlib_flags.items) catch @panic("OOM");
    iwasm.addCSourceFiles(.{ .files = iwasm_sources.items, .flags = iwasm_flags.items });
    b.installArtifact(iwasm);

    if (build_aot) {
        const wamrc = b.addExecutable(.{
            .name = "wamrc",
            .target = target,
            .optimize = optimize,
        });
        wamrc.want_lto = false;
        wamrc.disable_sanitize_c = true;
        if (optimize == .ReleaseFast)
            vmlib.strip = true;
        wamrc.use_llvm = true;
        wamrc.step.dependOn(&vmlib.step);
        wamrc.linkLibC();
        wamrc.linkLibCpp();
        wamrc.addLibraryPath(.{ .path = "C:/Development/zelosfarm_old/llvm-project-llvmorg-15.0.7/llvm/build-debug/lib" });
        wamrc.linkLibrary(vmlib);

        wamrc.addCSourceFiles(.{ .files = &.{"wamr-compiler/main.c"}, .flags = &.{"-DCOMPILING_WASM_RUNTIME_API=1"} });
        wamrc.addIncludePath(.{ .path = "core/iwasm/include" });
        wamrc.addIncludePath(.{ .path = "core/shared/utils" });
        wamrc.addIncludePath(.{ .path = "core/shared/utils/uncommon" });
        wamrc.addIncludePath(.{ .path = "core/shared/platform/include" });
        wamrc.addCSourceFiles(.{ .files = &.{
            "core/shared/utils/uncommon/bh_getopt.c",
            "core/shared/utils/uncommon/bh_read_file.c",
        }, .flags = &.{""} });
        switch (os_tag) {
            .windows => {
                wamrc.addIncludePath(.{ .path = "core/shared/platform/windows" });

                wamrc.linkSystemLibrary("Ole32");
                wamrc.linkSystemLibrary("Dbghelp");
                wamrc.linkSystemLibrary("iphlpapi");
                wamrc.linkSystemLibrary("psapi");
                wamrc.linkSystemLibrary("userenv");
                wamrc.linkSystemLibrary("ws2_32");
            },
            .linux => {
                wamrc.addIncludePath(.{ .path = "core/shared/platform/linux" });
            },
            else => @panic("unsupported os"),
        }

        wamrc.defineCMacroRaw("BUILD_TARGET_AMD_64");

        b.installArtifact(wamrc);
    }
}
