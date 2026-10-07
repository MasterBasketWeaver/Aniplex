tableextension 50200 "BAAN Inv. Posting Buffer" extends "Invoice Posting Buffer"
{
    fields
    {
        field(50200; "BAAN Item Line Description"; Text[100])
        {
            Caption = 'Item Line Description';
            DataClassification = CustomerContent;
        }
    }
}
