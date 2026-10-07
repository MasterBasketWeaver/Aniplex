pageextension 50150 "ISSAFI General Ledger Entries" extends "General Ledger Entries"
{
    layout
    {
        addafter(Description)
        {
            field("ISSAFI Item Line Description"; Rec."ISSAFI Item Line Description")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
