page 89000 "BAAN Test Runs API"
{
    PageType = API;
    APIPublisher = 'bryana';
    APIGroup = 'itemLinePostingTest';
    APIVersion = 'v1.0';
    EntityName = 'testRun';
    EntitySetName = 'testRuns';
    EntityCaption = 'Item Line Posting Test Run';
    EntitySetCaption = 'Item Line Posting Test Runs';
    SourceTable = "BAAN Test Run";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                }
                field(startedAt; Rec."Started At")
                {
                    Editable = false;
                }
                field(finishedAt; Rec."Finished At")
                {
                    Editable = false;
                }
                field(testsPassed; Rec."Tests Passed")
                {
                    Editable = false;
                }
                field(testsFailed; Rec."Tests Failed")
                {
                    Editable = false;
                }
                field(result; ResultText)
                {
                    Caption = 'Result';
                    Editable = false;
                }
            }
        }
    }

    var
        ResultText: Text;

    trigger OnAfterGetRecord()
    begin
        ResultText := Rec.GetResultText();
    end;

    [ServiceEnabled]
    procedure Run(var ActionContext: WebServiceActionContext)
    begin
        Rec.RunTests();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"BAAN Test Runs API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
