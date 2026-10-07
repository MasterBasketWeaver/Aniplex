tableextension 50150 "ISSAFI Inv. Posting Buffer" extends "Invoice Posting Buffer"
{
    fields
    {
        field(50150; "ISSAFI Item Line Description"; Text[100])
        {
            Caption = 'Item Line Description';
            DataClassification = CustomerContent;
        }
    }
}
