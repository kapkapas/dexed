unit ce_infos;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, strutils,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  StdCtrls, ExtCtrls, Buttons, Menus,ce_widget, ce_common, ce_sharedres,
  ce_interfaces;

type

  TToolInfoKind = (tikRunning, tikFindable, tikOptional);

  TToolInfo = class(TWinControl)
  private
    fLabel: TLabel;
    fStatus: TStaticText;
    fKind: TToolInfoKind;
    fToolName: string;
    fIco: TSpeedButton;
    fPresent: boolean;
    procedure buttonClick(sender: TObject);
  protected
    procedure SetVisible(Value: Boolean); override;
  public
    constructor Construct(TheOwner: TComponent; kind: TToolInfoKind;
      const toolName, description: string);
    procedure refreshStatus;
    procedure Update; override;
    property present: boolean read fPresent;
  end;


  { TCEInfoWidget }

  TCEInfoWidget = class(TCEWidget)
    boxTools: TScrollBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
  private
    procedure RefreshAllStatus;
    function findCriticalyMissingTool: boolean;
  protected
    procedure SetVisible(Value: Boolean); override;
  public
    constructor create(aOwner: TComponent); override;
    property hasMissingTools: boolean read findCriticalyMissingTool;
  end;

implementation

{$R *.lfm}

constructor TToolInfo.Construct(TheOwner: TComponent; kind: TToolInfoKind;
    const toolName, description: string);
begin
  Inherited create(TheOwner);
  Align  := alTop;
  height := 26;
  width := 200;
  //
  fLabel := TLabel.Create(self);
  fLabel.AutoSize:=false;
  fLabel.Parent := self;
  fLabel.Align:= alLeft;
  fLabel.Width:= 70;
  fLabel.BorderSpacing.Around := 2;
  fLabel.Hint:= description;
  fLabel.ShowHint:=true;
  //
  fIco := TSpeedButton.Create(self);
  fIco.Parent := self;
  fIco.Align:= alLeft;
  fIco.Width:= 22;
  fIco.Flat:=true;
  fIco.BorderSpacing.Around := 2;
  fIco.OnClick:= @buttonClick;
  fIco.Hint:= 'refresh the status';
  fIco.ShowHint:= true;
  //
  fStatus := TStaticText.Create(self);
  fStatus.Parent:=self;
  fStatus.Align:= alClient;
  fStatus.BorderSpacing.Around := 2;
  fStatus.BorderStyle := sbsSunken;
  fStatus.AutoSize:=false;
  fStatus.Width:= 800;
  fStatus.Hint:=description;
  fStatus.ShowHint:=true;
  //
  fKind:=kind;
  fToolName:=toolName;
  refreshStatus;
end;

procedure TToolInfo.SetVisible(Value: Boolean);
begin
  inherited;
  refreshStatus;
end;

procedure TToolInfo.Update;
begin
  inherited;
  refreshStatus;
end;

procedure TToolInfo.buttonClick(sender: TObject);
begin
  refreshStatus;
end;

procedure TToolInfo.refreshStatus;
var
  pth: string;
begin
  if fLabel.isNil or fStatus.isNil then exit;
  //
  fPresent := false;
  fLabel.Caption:= fToolName;
  case fKind of
    tikFindable:
    begin
      pth := exeFullName(fToolName + exeExt);
      if pth.isEmpty then
      begin
        fStatus.Caption:= ' the tool cannot be found';
        AssignPng(fIco, 'BULLET_RED');
      end
      else
      begin
        fStatus.Caption:= ' the tool is available';
        AssignPng(fIco, 'BULLET_GREEN');
        fPresent := true;
      end;
    end;
    tikOptional:
    begin
      pth := exeFullName(fToolName + exeExt);
      if pth.isEmpty then
      begin
        fStatus.Caption:= ' the tool cannot be found';
        AssignPng(fIco, 'BULLET_YELLOW');
      end
      else
      begin
        fStatus.Caption:= ' the tool is available';
        AssignPng(fIco, 'BULLET_GREEN');
        fPresent := true;
      end;
    end;
    tikRunning:
    begin
      pth := exeFullName(fToolName + exeExt);
      if pth.isEmpty then
      begin
        fStatus.Caption:= ' the tool cannot be found';
        AssignPng(fIco, 'BULLET_RED');
      end
      else if AppIsRunning(fToolName + exeExt) then
      begin
        fStatus.Caption:= ' the tool is available and running';
        AssignPng(fIco, 'BULLET_GREEN');
        fPresent := true;
      end
      else
      begin
        fStatus.Caption:= ' the tool is available but is not running';
        AssignPng(fIco, 'BULLET_YELLOW');
        fPresent := true;
      end;
    end;
  end;
  ReAlign;
  Invalidate;
end;

constructor TCEInfoWidget.create(aOwner: TComponent);
var
  itm: TToolInfo;
  ver: string = 'enough_space_for_the_version';
  len: integer;
begin
  inherited;
  toolbarVisible:=false;
  fIsModal := true;
  fIsDockable := false;
  //
  with TResourceStream.Create(HINSTANCE, 'VERSION', RT_RCDATA) do
  try
    len := read(ver[1], ver.length);
    setLength(ver, len);
    Label1.Caption := 'Coedit - ' + ver[1..ver.length];
  finally
    free;
  end;
  //
  itm := TToolInfo.Construct(self, tikOptional, 'diff',
      'The diff tool as included in linux or msysgit');
  itm.Parent := boxTools;
  itm.ReAlign;
  {$IFDEF UNIX}
  itm := TToolInfo.Construct(self, tikOptional, 'gdb',
      'optional, the GNU debugger');
  itm.Parent := boxTools;
  itm.ReAlign;
  {$ENDIF}
  itm := TToolInfo.Construct(self, tikOptional, 'dscanner',
    'optional, the D source code analyzer');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikOptional, 'dfmt',
    'optional, the D source code formater, needed by the Dfmt commander widget');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikOptional, 'gdc',
    'optional, the GDC D compiler');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikOptional, 'ldc2',
    'optional, the LDC D compiler');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikFindable, 'ddemangle',
    'optional, allows to demangle the symbols in the message widget');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikRunning, 'dcd-server',
    'mandatory, provides IDE-grade features such as the completion');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikFindable, 'dcd-client',
    'mandatory, provides IDE-grade features such as the completion');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikFindable, 'dastworx',
    'background tool that processes the D modules to extract informations' +
    LineEnding + 'such as the declarations, the imports, the "TODO" comments, etc.');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikOptional, 'dub',
    'the D package manager, mandatory to compile project in DUB format');
  itm.Parent := boxTools;
  itm.ReAlign;
  itm := TToolInfo.Construct(self, tikFindable, 'dmd',
    'mandatory, the reference D compiler');
  itm.Parent := boxTools;
  itm.ReAlign;
  //
  Height := boxTools.ControlCount * 30 + 150;
  Realign;
end;

function TCEInfoWidget.findCriticalyMissingTool: boolean;
var
  i: integer;
  t: TToolInfo;
begin
  result := false;
  for i := 0 to boxTools.ControlCount -1 do
  begin
    if not (boxTools.Controls[i] is TToolInfo) then
      continue;
    t := TToolInfo(boxTools.Controls[i]);
    t.refreshStatus;
    if (t.fKind in [tikFindable, tikRunning]) and not t.present then
      result := true;
  end;
end;

procedure TCEInfoWidget.RefreshAllStatus;
var
  i: integer;
  s: string = '';
  t: TToolInfo;
begin
  for i := 0 to boxTools.ControlCount -1 do
  begin
    if not (boxTools.Controls[i] is TToolInfo) then
      continue;
    t := TToolInfo(boxTools.Controls[i]);
    t.refreshStatus;
    if (t.fKind in [tikFindable, tikRunning]) and not t.present then
      s += ' ' + t.fToolName;
  end;
  if s.isNotEmpty then
    getMessageDisplay.message('Some tools cannot be found:' + s, nil, amcApp, amkWarn);
end;

procedure TCEInfoWidget.SetVisible(Value: Boolean);
begin
  inherited;
  if Visible then
    RefreshAllStatus;
end;

end.

