tableextension 50152 "ISSAFI G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(50150; "ISSAFI Item Line Description"; Text[100])
        {
            Caption = 'Item Line Description';
            ToolTip = 'Specifies the description of the sales Item line that this entry was posted from.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
