table 50900 "BAAN Test Run"
{
    Caption = 'Item Line Posting Test Run';
    DataClassification = SystemMetadata;
    Access = Internal;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(3; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
        }
        field(4; "Tests Passed"; Integer)
        {
            Caption = 'Tests Passed';
        }
        field(5; "Tests Failed"; Integer)
        {
            Caption = 'Tests Failed';
        }
        field(6; Result; Blob)
        {
            Caption = 'Result';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    // Nothing may be written before the runner starts: the tests run inside it, and their
    // isolation must not wrap a write transaction this record already opened.
    procedure RunTests()
    var
        TestResults: Codeunit "BAAN Test Results";
        StartedAt: DateTime;
    begin
        StartedAt := CurrentDateTime();
        TestResults.Reset();
        Codeunit.Run(Codeunit::"BAAN Test Runner");

        "Started At" := StartedAt;
        "Finished At" := CurrentDateTime();
        "Tests Passed" := TestResults.Passed();
        "Tests Failed" := TestResults.Failed();
        SetResultText(TestResults.GetText());
        Modify();
    end;

    procedure GetResultText() Content: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        CalcFields(Result);
        Result.CreateInStream(InStr, TextEncoding::UTF8);
        TypeHelper.TryReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator(), Content);
    end;

    local procedure SetResultText(Content: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Result);
        Result.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
    end;
}
