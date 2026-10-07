// Held in memory rather than in a table because the runner's isolation rolls back what the tests write.
codeunit 50902 "BAAN Test Results"
{
    SingleInstance = true;
    Access = Internal;

    var
        Output: TextBuilder;
        PassedCount: Integer;
        FailedCount: Integer;

    procedure Reset()
    begin
        Clear(Output);
        PassedCount := 0;
        FailedCount := 0;
    end;

    procedure StartTest(FunctionName: Text)
    begin
        Output.AppendLine('== ' + FunctionName);
    end;

    procedure Log(Line: Text)
    begin
        Output.AppendLine('   ' + Line);
    end;

    procedure FinishTest(FunctionName: Text; Success: Boolean; ErrorText: Text; ErrorCallStack: Text)
    begin
        if Success then begin
            PassedCount += 1;
            Output.AppendLine('PASS ' + FunctionName);
        end else begin
            FailedCount += 1;
            Output.AppendLine('FAIL ' + FunctionName + ': ' + ErrorText);
            Output.AppendLine(ErrorCallStack);
        end;
    end;

    procedure Passed(): Integer
    begin
        exit(PassedCount);
    end;

    procedure Failed(): Integer
    begin
        exit(FailedCount);
    end;

    procedure GetText(): Text
    begin
        exit(Output.ToText());
    end;
}
