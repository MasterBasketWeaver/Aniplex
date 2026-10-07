permissionset 50170 "ISSAFT Tests"
{
    Caption = 'Item Line Posting Tests';
    Assignable = true;
    Permissions =
        tabledata "ISSAFT Test Run" = RIMD,
        table "ISSAFT Test Run" = X,
        page "ISSAFT Test Runs API" = X,
        codeunit "ISSAFT Test Runner" = X,
        codeunit "ISSAFT Test Results" = X,
        codeunit "ISSAFT Item Line Split Test" = X;
}
