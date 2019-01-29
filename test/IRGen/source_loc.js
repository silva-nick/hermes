// RUN: %hermes -dump-source-location -dump-ir < %s | %FileCheck --match-full-lines %s

function foo(a,b) {
    if (a > b) {
        a -= b;
        print(a);
    } else {
        b -= a;
        print(b);
    }
}

//CHECK-LABEL: function global()
//CHECK-NEXT: frame = [], globals = [foo]
//CHECK-NEXT: source location: [<stdin>:3:1 ... <stdin>:85:1)
//CHECK-NEXT: %BB0:
//CHECK-NEXT: ; <stdin>:3:1
//CHECK-NEXT:   %0 = CreateFunctionInst %foo()
//CHECK-NEXT: ; <stdin>:3:1
//CHECK-NEXT:   %1 = StorePropertyInst %0 : closure, globalObject : object, "foo" : string
//CHECK-NEXT: ; <stdin>:3:1
//CHECK-NEXT:   %2 = AllocStackInst $?anon_0_ret
//CHECK-NEXT: ; <stdin>:3:1
//CHECK-NEXT:   %3 = StoreStackInst undefined : undefined, %2
//CHECK-NEXT: ; <stdin>:3:1
//CHECK-NEXT:   %4 = LoadStackInst %2
//CHECK-NEXT: ; <stdin>:84:27
//CHECK-NEXT:   %5 = ReturnInst %4
//CHECK-NEXT: function_end

//CHECK-LABEL: function foo(a, b)
//CHECK-NEXT: frame = [a, b]
//CHECK-NEXT: source location: [<stdin>:3:19 ... <stdin>:11:2)
//CHECK-NEXT: %BB0:
//CHECK-NEXT: ; <stdin>:3:19
//CHECK-NEXT:   %0 = StoreFrameInst %a, [a]
//CHECK-NEXT: ; <stdin>:3:19
//CHECK-NEXT:   %1 = StoreFrameInst %b, [b]
//CHECK-NEXT: ; <stdin>:4:9
//CHECK-NEXT:   %2 = LoadFrameInst [a]
//CHECK-NEXT: ; <stdin>:4:13
//CHECK-NEXT:   %3 = LoadFrameInst [b]
//CHECK-NEXT: ; <stdin>:4:9
//CHECK-NEXT:   %4 = BinaryOperatorInst '>', %2, %3
//CHECK-NEXT: ; <stdin>:4:5
//CHECK-NEXT:   %5 = CondBranchInst %4, %BB1, %BB2
//CHECK-NEXT: %BB1:
//CHECK-NEXT: ; <stdin>:5:9
//CHECK-NEXT:   %6 = LoadFrameInst [a]
//CHECK-NEXT: ; <stdin>:5:14
//CHECK-NEXT:   %7 = LoadFrameInst [b]
//CHECK-NEXT: ; <stdin>:5:11
//CHECK-NEXT:   %8 = BinaryOperatorInst '-', %6, %7
//CHECK-NEXT: ; <stdin>:5:11
//CHECK-NEXT:   %9 = StoreFrameInst %8, [a]
//CHECK-NEXT: ; <stdin>:6:9
//CHECK-NEXT:   %10 = TryLoadGlobalPropertyInst globalObject : object, "print" : string
//CHECK-NEXT: ; <stdin>:6:15
//CHECK-NEXT:   %11 = LoadFrameInst [a]
//CHECK-NEXT: ; <stdin>:6:14
//CHECK-NEXT:   %12 = CallInst %10, undefined : undefined, %11
//CHECK-NEXT: ; <stdin>:4:5
//CHECK-NEXT:   %13 = BranchInst %BB3
//CHECK-NEXT: %BB2:
//CHECK-NEXT: ; <stdin>:8:9
//CHECK-NEXT:   %14 = LoadFrameInst [b]
//CHECK-NEXT: ; <stdin>:8:14
//CHECK-NEXT:   %15 = LoadFrameInst [a]
//CHECK-NEXT: ; <stdin>:8:11
//CHECK-NEXT:   %16 = BinaryOperatorInst '-', %14, %15
//CHECK-NEXT: ; <stdin>:8:11
//CHECK-NEXT:   %17 = StoreFrameInst %16, [b]
//CHECK-NEXT: ; <stdin>:9:9
//CHECK-NEXT:   %18 = TryLoadGlobalPropertyInst globalObject : object, "print" : string
//CHECK-NEXT: ; <stdin>:9:15
//CHECK-NEXT:   %19 = LoadFrameInst [b]
//CHECK-NEXT: ; <stdin>:9:14
//CHECK-NEXT:   %20 = CallInst %18, undefined : undefined, %19
//CHECK-NEXT: ; <stdin>:4:5
//CHECK-NEXT:   %21 = BranchInst %BB3
//CHECK-NEXT: %BB3:
//CHECK-NEXT: ; <stdin>:11:1
//CHECK-NEXT:   %22 = ReturnInst undefined : undefined
//CHECK-NEXT: function_end
