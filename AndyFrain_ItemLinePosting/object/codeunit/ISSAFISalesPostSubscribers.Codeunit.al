codeunit 50150 "ISSAFI Sales Post Subscribers"
{
    Access = Internal;

    // Additional Grouping Identifier is part of the Invoice Posting Buffer's Group ID key and
    // Base Application never sets it, so putting the line number there splits Item lines without
    // borrowing Fixed Asset Line No. the way "Copy Line Descr. to G/L Entry" does.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnAfterPrepareInvoicePostingBuffer', '', false, false)]
    local procedure SplitItemLine(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        InvoicePostingBuffer."Additional Grouping Identifier" := Format(SalesLine."Line No.", 0, 9);
        InvoicePostingBuffer."ISSAFI Item Line Description" := SalesLine.Description;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invoice Posting Buffer", 'OnAfterCopyToGenJnlLine', '', false, false)]
    local procedure CopyItemLineDescriptionToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        GenJnlLine."ISSAFI Item Line Description" := InvoicePostingBuffer."ISSAFI Item Line Description";
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure CopyItemLineDescriptionToGLEntry(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."ISSAFI Item Line Description" := GenJournalLine."ISSAFI Item Line Description";
    end;
}
