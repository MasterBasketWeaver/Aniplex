pageextension 50200 "BAAN General Ledger Entries" extends "General Ledger Entries"
{
    layout
    {
        addafter(Description)
        {
            field("BAAN Item Line Description"; Rec."BAAN Item Line Description")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
