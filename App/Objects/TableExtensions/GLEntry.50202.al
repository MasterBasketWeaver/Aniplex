tableextension 50202 "BAAN G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(50200; "BAAN Item Line Description"; Text[100])
        {
            Caption = 'Item Line Description';
            ToolTip = 'Specifies the description of the sales Item line that this entry was posted from.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
