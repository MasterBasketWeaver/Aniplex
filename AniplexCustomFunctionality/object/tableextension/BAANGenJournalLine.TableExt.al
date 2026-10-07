tableextension 80001 "BAAN Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(80000; "BAAN Item Line Description"; Text[100])
        {
            Caption = 'Item Line Description';
            DataClassification = CustomerContent;
        }
    }
}
