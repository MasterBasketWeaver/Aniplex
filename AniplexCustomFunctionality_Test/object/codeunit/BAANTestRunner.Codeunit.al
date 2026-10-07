codeunit 89001 "BAAN Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;
    Access = Internal;

    var
        TestResults: Codeunit "BAAN Test Results";

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"BAAN Item Line Split Test");
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        ClearLastError();
        if FunctionName <> '' then
            TestResults.StartTest(FunctionName);
        exit(true);
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; Success: Boolean)
    begin
        if (FunctionName = '') and Success then
            exit;

        if FunctionName = '' then
            FunctionName := CodeunitName;
        TestResults.FinishTest(FunctionName, Success, GetLastErrorText(), GetLastErrorCallStack());
    end;
}
