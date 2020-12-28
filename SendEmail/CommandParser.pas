{ *************************************************************************** }
{                                                                             }
{ Delphi and Kylix Cross-Platform Components                                  }
{                                                                             }
{ Copyright (c) 1995-2008 CodeGear                                            }
{                                                                             }
{ *************************************************************************** }
unit CommandParser;

interface

uses Classes, SysUtils, Generics.Defaults, Generics.Collections;

type

  TSwitchType = (stString, stInteger, stDate, stDateTime, stFloat, stBoolean);

  ECommandParser = class(Exception);

  TCommandSwitch = class
    Name: string;
    Kind: TSwitchType;
    Required: boolean;
    Default: string;
    LongName: string;
    UniqueAt: integer;
    PropertyName: string;
    Description: string;
    Value: string;
    function SwitchSyntax(const ADefSwitch: char): string;
    function Syntax(const ADefSwitch, ADefArg: char): string;
    function Assigned: boolean;
    function Named: boolean;
    function Positional: boolean;
    function ParamName: string;
    function Optional: boolean;
    function HasDefault: boolean;
    function CurrentValue: string;
    function QuotedValue(AValue: string = ''): string;
    function HasValue: boolean;
    function HasProperty: boolean;
    procedure SetProperty(const AObject: TPersistent);
    function GetProperty(const AObject: TPersistent): string;
    procedure SetBoolean(const AObject: TPersistent; ATrueVals: string = '');
    constructor Create(const AName: string; const AKind: TSwitchType;
      const ARequired: boolean = False; const ADefault: string = '';
      const ADescription: string = ''; const ALongName: string = '';
      const APropertyName: string = '');
  end;

  TSwitchRef = record
    Name: string;
    SwitchPos: integer;
    constructor Create(const AName: string; const ASwitchPos: integer);
  end;

  TSwitchNames = class(TList<TSwitchRef>)
  public
    function Find(const Item: TSwitchRef; out FoundIndex: Integer;
      const Comparer: IComparer<TSwitchRef>; Index: Integer): Boolean; overload;
    function Find(const Item: TSwitchRef; out FoundIndex: Integer;
      const Comparer: IComparer<TSwitchRef>): Boolean; overload;
  end;

  TSwitchComparer = class(TComparer<TSwitchRef>)
  private
    FCaseSensitive: boolean;
    procedure SetCaseSensitive(const Value: boolean);
  public
    property CaseSensitive: boolean read FCaseSensitive write SetCaseSensitive;
    function Compare(const Left, Right: TSwitchRef): Integer; override;
    constructor Create(ACaseSensitive: boolean); overload;
  end;

  TArgComparer = class(TSwitchComparer)
  public
    function Compare(const Left, Right: TSwitchRef): Integer; override;
  end;

  TCommandSwitches = class(TList<TCommandSwitch>)
  public
    destructor Destroy; override;
  end;

  TCommandParser = class(TComponent)
  private
    FCaseSensitive: boolean;
    FTrueValues: string;
    FArgChars: string;
    FFalseValues: string;
    FSwitchChars: string;
    FSwitches: TCommandSwitches;
    FDefSwitch: char;
    FDescription: string;
    FRaiseErrors: boolean;
    FUnknown: string;
    FToggleChars: string;
    FValidation: string;
    FArguments: TStrings;
    FEnvArg: string;
    FContainer: TPersistent;
    FFileName: string;
    procedure ProcessEnvironment;
    procedure SetSwitchChars(const Value: string);

  protected
    procedure ProcessOption(const AOption: string; const ANames: TSwitchNames;
      const AComparer: TArgComparer);
    procedure FlagUnknown(const AOption: string);
    procedure ShowErrors;
    procedure InsertArguments(const AArgs: TStrings; const AInsertAt: integer);
    function SwitchNames: TSwitchNames;
    class constructor Create;

  public
    /// <summary>
    /// Default extension for configuration files, which is '.opt"
    /// </summary>
    class var ConfigExtension: string;

    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; ACaseSensitive: boolean;
      ADescription: string = ''; AEnvArg: string = ''); overload;
    destructor Destroy; override;

    function CheckNames: string;
    function Validate: boolean;
    procedure ProcessFile(const AOption: string; const AInsertAt: Integer);
    function ProcessCommandLine(ACommandLine: string = '') : boolean;
    procedure InsertSwitch(const AAt: integer; const AName: string;
      AKind: TSwitchType = stString;
      ARequired: Boolean = False; ADefault: string = '';
      ADescription: string = ''; ALongName: string = '';
      APropertyName: string = '');
    procedure AddSwitch(const AName: string; AKind: TSwitchType = stString;
      ARequired: Boolean = False; ADefault: string = '';
      ADescription: string = ''; ALongName: string = '';
      APropertyName: string = ''); overload;
    procedure AddSwitch(AKind: TSwitchType; ALongName: string;
      ADescription: string = ''; ARequired: Boolean = True;
      ADefault: string = ''; APropertyName: string = ''); overload;
    function Syntax: string;
    function HelpText: string;
    function Options(const ALongNames: Boolean = true): UnicodeString;
    function SaveOptions(const AFileName: UnicodeString;
      const ALongName: Boolean = true): boolean;
    function IndexOf(AOption: string): integer;
    function ArgumentCount: integer;
  published
    property Container: TPersistent read FContainer write FContainer;
    property CaseSensitive: boolean read FCaseSensitive write FCaseSensitive
      default False;
    property FileName: string read FFileName write FFileName;
    property SwitchChars: string read FSwitchChars write SetSwitchChars;
    property ArgChars: string read FArgChars write FArgChars;
    property ToggleChars: string read FToggleChars write FToggleChars;
    property TrueValues: string read FTrueValues write FTrueValues;
    property FalseValues: string read FFalseValues write FFalseValues;
    property Description: string read FDescription write FDescription;
    property RaiseErrors: boolean read FRaiseErrors write FRaiseErrors
      default True;
    property EnvArg: string read FEnvArg write FEnvArg;
    property Switches: TCommandSwitches read FSwitches write FSwitches;

  end;

procedure ProcessCommandLine(ACommandText: String; ACommandList: TStrings);
function ProcessEnvArgs(const AEnvName: string): TStrings;
function ProcessFileArgs(const AFileName: string): TStrings;

implementation

uses
  RTLConsts, PropertyHelpers, StrUtils, Windows;

const
  SValSep = '|';                            // DO NOT LOCALIZE
  SSwitchCharDefaults = '/-';               // DO NOT LOCALIZE
  SArgCharDefaults = ':=';                  // DO NOT LOCALIZE
  STrueDefaults = '|y|t|on|yes|true|+|';    // DO NOT LOCALIZE
  SFalseDefaults = '|n|f|off|no|false|-|';  // DO NOT LOCALIZE
  SToggleDefaults = '+-';                   // DO NOT LOCALIZE
  NL = #13#10;                              // DO NOT LOCALIZE

resourcestring
  StrAmbiguousSwitch = 'Ambiguous switch definition: "%s" (%s)'+NL;
  StrInvalidFormat = 'Invalid format for "%s". Expected %s and got "%s"'+NL;
  StrRequiredSwitch = 'Missing required switch: "%s"'+ NL;
  StrAmbiguousParam = 'Unrecognized parameter: "%s"'+NL;
  StrUnknown = 'Unknown parameter: "%s"'+NL;
  strUnassignedCommandList = 'CommandList must be assigned.';
  strPositionalBeforeDeclared  =  'Positional switches must be declared before named switches';
  strFileNotFound = 'File "%s" was not found';

type
  TAnsiChars = set of AnsiChar;

function Any(Chars: TAnsiChars; Target: string): integer;
var
  i, j : integer;
begin
  j := Length(Target);
  for i := 1 to j do
    if CharInSet(Target[i], Chars) then
      Exit(i);
  Result := -1;
end;

function CompareNames(Left, Right: string; CaseSensitive: boolean): integer;
begin
  if CaseSensitive then
    Result := CompareStr(Left, Right, loInvariantLocale)
  else
    Result := CompareText(Left, Right, loInvariantLocale);
end;

const
  QuoteSet = ['"',#39];

function NoQuote(AValue: string): string;
var
  i: integer;
begin
  i := Length(AValue);
  if (i > 0) and CharInSet(AValue[1], QuoteSet) and (AValue[1] = AValue[i]) then
    Result := Copy(AValue, 2, i - 2)
  else
    Result := AValue;
end;

procedure ProcessCommandLine(ACommandText: String; ACommandList: TStrings);
var
  I: Integer;
  L: Integer;
  LastPos: Integer;
  Temp: String;
  CurChar,
  Quote: char;
  function InQuote: boolean;
  begin
    Result := Quote <> #0;
  end;


begin
  if not Assigned(ACommandList) then
    raise ECommandParser.Create(strUnassignedCommandList);

  LastPos := 1;
  Quote := #0;

  I := 1;
  L := Length(ACommandText);
	while I <= L do
  begin
    CurChar := ACommandText[I];
		if CharInSet(CurChar, QuoteSet) then
    begin
      if (CurChar = Quote) then // Implicitly InQuote
        Quote := #0
      else
        Quote := CurChar;
    end
		else if (CharInSet(CurChar, [#10, #13, ' '])) and (not InQuote) then
    begin
			Temp := Trim(Copy(ACommandText, LastPos, I - LastPos));
      if Length(Temp) > 0 then
        ACommandList.Add(NoQuote(Temp));
			LastPos := I + 1;
    end;

    Inc(I);
  end;

	if LastPos < I then
  begin
		Temp := Trim(Copy(ACommandText, LastPos, i - LastPos));
		ACommandList.Add(NoQuote(Temp));
  end;
end;

function ProcessEnvArgs(const AEnvName: string): TStrings;
begin
  Result := TStringList.Create;
  ProcessCommandLine(GetEnvironmentVariable(AEnvName), Result);
end;

function ProcessFileArgs(const AFileName: string): TStrings;
var
  s: string;
begin
  Result := TStringList.Create;
  if not FileExists(AFileName) then
    Raise ECommandParser.CreateFmt(strFileNotFound, [AFileName]);
  Result.LoadFromFile(AFileName);
  s := Result.Text;
  Result.Clear;
  ProcessCommandLine(s, Result);
end;

{ TCommandSwitch }

function TCommandSwitch.Assigned: boolean;
begin
  Result := Length(Value) > 0;
end;

constructor TCommandSwitch.Create(const AName: string; const AKind: TSwitchType;
  const ARequired: boolean; const ADefault, ADescription, ALongName,
  APropertyName: string);
begin
  Name := AName;
  Kind := AKind;
  Required := ARequired;
  Default := ADefault;
  Description := ADescription;
  LongName := ALongName;
  PropertyName := APropertyName;
end;

function TCommandSwitch.CurrentValue: string;
begin
  if Length(Value) > 0 then
    Result := Value
  else
    Result := Default;
end;

function TCommandSwitch.HasDefault: boolean;
begin
  Result := Length(Default) > 0;
end;

function TCommandSwitch.HasProperty: boolean;
begin
  Result := Length(PropertyName) > 0;
end;

function TCommandSwitch.HasValue: boolean;
begin
  Result := Length(CurrentValue) > 0;
end;

function TCommandSwitch.Named: boolean;
begin
  Result := Length(Name) > 0;
end;

function TCommandSwitch.Optional: boolean;
begin
  Result := not Required;
end;

procedure TCommandSwitch.SetBoolean(const AObject: TPersistent;
  ATrueVals: string = '');
var
  toggle: string;
begin
  if HasProperty then
  begin
    if Length(ATrueVals) = 0 then
      ATrueVals := STrueDefaults;
    if Pos(SValSep + LowerCase(CurrentValue) + SValSep,
      LowerCase(ATrueVals)) > 0 then
      toggle := 'true'
    else
      toggle := 'false';
    SetPropertyValue(AObject, PropertyName, toggle, true);
  end;
end;

procedure TCommandSwitch.SetProperty(const AObject: TPersistent);
var
  v: string;
begin
  if HasProperty then
  begin
    v := CurrentValue;
    case Kind of
      stDate:
        SetPropertyValue(AObject, PropertyName, StrToDate(v), true);
      stDateTime:
        SetPropertyValue(AObject, PropertyName, StrToDateTime(v),
          true);
      else
        SetPropertyValue(AObject, PropertyName, v, true);
    end;
  end;
end;

function TCommandSwitch.GetProperty(const AObject: TPersistent): string;
begin
  if HasProperty then
  begin
    Value := GetPropertyValue(AObject, PropertyName, true);
    Result := Value;
  end;
end;

function TCommandSwitch.SwitchSyntax(const ADefSwitch: Char): string;
const
  SOr = '| ';

  function OpenOpt: string;
  begin
    if Optional then
      Result := '['
    else
      Result := '';
  end;

  function CloseOpt: string;
  begin
    if Optional then
      Result := ']'
    else
      Result := '';
  end;

  function DistinctName: string;
  begin
    if UniqueAt > 0 then
      Result := sOr + ADefSwitch + Copy(LongName, 1, UniqueAt)
    else
      Result := ''; // Result + ' u:' + IntToStr(UniqueAt);
  end;

begin
  { TODO : Indicate the distinct characters for the long switch name in the syntax output }
  if Positional then
  begin
    Result := OpenOpt + ParamName + CloseOpt;
  end
  else if Length(LongName) > 0 then
    Result := OpenOpt + ADefSwitch + LongName + DistinctName + sOr + ADefSwitch + Name
      + CloseOpt
  else
    Result := OpenOpt + ADefSwitch + Name + CloseOpt;
end;

function TCommandSwitch.ParamName: string;
begin
  if Length(LongName) > 0 then
    Result := LongName
  else if Length(Name) > 0 then
    Result := Name
  else
    Result := Description;
end;

function TCommandSwitch.Positional: boolean;
begin
  Result := not Named;
end;

function TCommandSwitch.QuotedValue(AValue: string = ''): string;
begin
  if Length(AValue) = 0 then
    AValue := CurrentValue;
  if Kind = stString then
  begin
    if Any([' ','/','-',':',','], AValue) > 0  then
      Result := '"' + AValue + '"'
    else
      Result := AValue;
  end
  else if Kind in [stDate, stDateTime] then
    Result := '"' + AValue + '"'
  else
    Result := AValue;
end;

function TCommandSwitch.Syntax(const ADefSwitch, ADefArg: char): string;

  function OptionalText: string;
  begin
    if Optional then
      Result := ' (Optional)'
    else
      Result := '';
  end;

begin
  Result := SwitchSyntax(ADefSwitch);

  if Length(Description) > 0 then
    Result := Result + ' - ' + Description + OptionalText;
  if Length(Default) > 0 then
    Result := Result + NL + '    Default: ' + QuotedValue(Default)
      + '. Example: ' + ADefSwitch + Name + ADefArg + QuotedValue(Default);
  if Length(Value) > 0 then
    Result := Result + '. Config: ' + ADefSwitch + ParamName + ADefArg + QuotedValue(Value);
  Result := Result + NL;

end;

{ TCommandParser }

procedure TCommandParser.AddSwitch(const AName: string;
  AKind: TSwitchType = stString; ARequired: Boolean = False;
  ADefault: string = ''; ADescription: string = ''; ALongName: string = '';
  APropertyName: string = '');
var
  i: integer;
begin
  i := FSwitches.Count;
  // if Name is blank, switch is positional
  if (Length(AName) = 0) and (i>0) and (FSwitches[i-1].Named) then
    Raise ECommandParser.Create(strPositionalBeforeDeclared);

  FSwitches.Add(TCommandSwitch.Create(AName, AKind, ARequired, ADefault,
    ADescription, ALongName, APropertyName));
end;

procedure TCommandParser.AddSwitch(AKind: TSwitchType; ALongName,
  ADescription: string; ARequired: Boolean; ADefault, APropertyName: string);
begin
  AddSwitch('', AKind, ARequired, ADefault, ADescription, ALongName,
    APropertyName);
end;

function TCommandParser.ArgumentCount: integer;
begin
  Result := FArguments.Count;
end;

procedure TCommandParser.ProcessFile(const AOption: string;
  const AInsertAt: Integer);
var
  NewArgs: TStrings;
begin
  // Add arguments in the file
  NewArgs := ProcessFileArgs(AOption);
  try
    InsertArguments(NewArgs, AInsertAt);
  finally
    FreeAndNil(NewArgs);
  end;
end;

procedure TCommandParser.ProcessEnvironment;
var
  NewArgs: TStrings;
begin
  if Length(FEnvArg) > 0 then
  // process environment variables
  begin
    NewArgs := ProcessEnvArgs(FEnvArg);
    try
      // Put these arguments first so they can be overridden with subsequent
      // switch value assignments
      InsertArguments(NewArgs, 0);
    finally
      FreeAndNil(NewArgs);
    end;
  end;
end;

function TCommandParser.CheckNames: string;
var
  Names: TSwitchNames;
  TestName: string;
  i, k, p, u: integer;
  islong : boolean;

  function MakeUnique(const ACandidate, APrev, ANext: string; IsLong: boolean): integer;
  var
    iCand, iPrev, iNext : integer;
    p: integer;
  begin
    if (ACandidate = APrev) or (ACandidate = ANext) then Exit(0); // not unique
    if (not IsLong) and (ACandidate <> APrev) and (ACandidate <> ANext) then
      Exit(1); // Short switch does not match values above and below it

    iCand := Length(ACandidate);
    iPrev := Length(APrev);
    iNext := Length(ANext);
    Result := 0;

    if FCaseSensitive then
    begin
      for p := 1 to iCand do
        if ((iPrev < p) or (Copy(ACandidate,1,p) <> Copy(APrev, 1, p)))
          and ((iNext < p) or (Copy(ACandidate,1,p) <> Copy(ANext, 1, p)))
        then
        begin
          Result := p;
          break;
        end;
    end
    else
      for p := 1 to iCand do
        if ((iPrev < p) or (not SameText(Copy(ACandidate,1,p), Copy(APrev, 1, p))))
          and ((iNext < p) or (not SameText(Copy(ACandidate,1,p), Copy(ANext, 1, p))))
        then
        begin
          Result := p;
          break;
        end;
  end;

begin
  Names := SwitchNames;
  try
    k := Names.Count - 1;
    Result := '';
    for i := 0 to k do
    begin
      TestName := Names[i].Name;
      p := Names[i].SwitchPos;
      IsLong := FSwitches[p].LongName = TestName;
      if i = 0 then
        u := MakeUnique(TestName, '', Names[i+1].Name, IsLong)
      else if i = k then
        u := MakeUnique(TestName, Names[i-1].Name, '', IsLong)
      else
        u := MakeUnique(TestName, Names[i-1].Name, Names[i+1].Name, IsLong);
      if u = 0 then // Is not unique
        Result := Result + Format(StrAmbiguousSwitch,
          [TestName, FSwitches[p].Description])
      else if IsLong then
        FSwitches[p].UniqueAt := u;
    end;
  finally
    Names.Free;
  end;
end;

constructor TCommandParser.Create(AOwner: TComponent;
  ACaseSensitive: boolean; ADescription: string = '';
  AEnvArg: string = '');
begin
  Create(AOwner);
  FCaseSensitive := ACaseSensitive;
  FDescription := ADescription;
  FEnvArg := AEnvArg;
end;

class constructor TCommandParser.Create;
begin
  inherited;
  ConfigExtension := '.opt';
end;

constructor TCommandParser.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFileName := ParamStr(0) + ConfigExtension;
  FContainer := AOwner;
  FCaseSensitive := False;
  SetSwitchChars(SSwitchCharDefaults);
  FArgChars := SArgCharDefaults;
  FToggleChars := SToggleDefaults;
  FTrueValues := STrueDefaults;
  FFalseValues := SFalseDefaults;
  FRaiseErrors := False;
  FArguments := TStringList.Create;
  FSwitches := TCommandSwitches.Create;
end;

destructor TCommandParser.Destroy;
begin
  FreeAndNil(FSwitches);
  FreeAndNil(FArguments);
  inherited;
end;

function TCommandParser.IndexOf(AOption: string): integer;
var
  i: integer;
  switch: TCommandSwitch;
begin
  { TODO : Modify this to report multiple switch matches }
  if FCaseSensitive then
  begin
    for i := 0 to FSwitches.Count - 1 do
    begin
      Switch := FSwitches[i];
      if (AOption = Switch.Name)
        or ((Length(Switch.LongName) > 0) and (AOption = Switch.Name)) then
      begin
        Result := i;
        exit;
      end;
    end;
  end
  else
  begin
    for i := 0 to FSwitches.Count - 1 do
    begin
      Switch := FSwitches[i];
      if SameText(AOption,Switch.Name) or ((Length(Switch.LongName) > 0)
        and SameText(AOption, Switch.LongName)) then
      begin
        Result := i;
        exit;
      end;
    end;

  end;
  Result := -1;
end;

procedure TCommandParser.InsertArguments(const AArgs: TStrings;
  const AInsertAt: integer);
var
  I: integer;
begin
  if AInsertAt >= Argumentcount then
    for I := 0 to AArgs.Count - 1 do
      FArguments.Add(AArgs[i])
  else
    for I := 0 to AArgs.Count - 1 do
      FArguments.Insert(AInsertAt + I, AArgs[i]);
end;

procedure TCommandParser.InsertSwitch(const AAt: integer; const AName: string;
  AKind: TSwitchType; ARequired: Boolean; ADefault, ADescription, ALongName,
  APropertyName: string);
begin
  FSwitches.Insert(AAt, TCommandSwitch.Create(AName, AKind, ARequired,
    ADefault, ADescription, ALongName, APropertyName));
end;

function TCommandParser.Options(const ALongNames: Boolean = True): UnicodeString;
var
  switch: TCommandSwitch;
begin
  Result := '';
  if ALongNames then
    for switch in FSwitches do
    begin
      Switch.GetProperty(FContainer);
      if Length(Switch.CurrentValue) > 0 then
        if ALongNames then
          Result := Result + FDefSwitch + Switch.LongName + '='
            + Switch.QuotedValue(Switch.CurrentValue) + NL
        else
          Result := Result + FDefSwitch + Switch.Name + '='
            + Switch.QuotedValue(Switch.CurrentValue) + NL;
    end;
end;

procedure TCommandParser.FlagUnknown(const AOption: string);
begin
  FUnknown := FUnknown + Format(StrUnknown, [AOption]);
end;

function TCommandParser.HelpText: string;
begin
  Result := '';
  if (Length(FValidation) > 0) then
    Result := FValidation + NL;
  if (Length(FUnknown) > 0) then
    Result := Result + FUnknown + NL;

  Result := Result + Syntax;

end;

function ExtractFirstName(const AFileName: string): string;
var
  i: integer;
begin
  Result := ExtractFileName(AFileName);
  i := LastDelimiter('.', Result);
  if i > 0 then
    Result := Copy(result, 1, i - 1);
end;

function TCommandParser.ProcessCommandLine(ACommandLine: string = ''): boolean;
var
  LoadCommandLine: boolean;
  SwitchCount,
  i: integer;
  firstname,
  exe,
  option: string;
  Names: TSwitchNames;
  ArgComp: TArgComparer;
begin
  FUnknown := '';

  LoadCommandLine := (ParamCount > 0) and (Length(ACommandLine) = 0);
  if LoadCommandLine then
    ACommandLine := GetCommandLine;
  SwitchCount := FSwitches.Count;
  FArguments.Clear;
  if Length(ACommandLine) > 0 then
  begin
    CommandParser.ProcessCommandLine(ACommandLine, FArguments);
    option := FArguments[0];
    exe := NoQuote(ParamStr(0));
    firstname := ExtractFirstName(exe);
    if SameText(option, exe, TLocaleOptions.loInvariantLocale)
      or SameText(option, ExtractFileName(exe), TLocaleOptions.loInvariantLocale)
      or SameText(option, firstname, TLocaleOptions.loInvariantLocale)
    then
      // Get rid of executable name
      FArguments.Delete(0);
  end;
  if FileExists(FileName) then
    // process the config file before command-line switch overrides
    FArguments.Insert(0, '@' + FileName);
  ProcessEnvironment;
  i := 0;
  Names := SwitchNames;
  ArgComp := TArgComparer.Create(FCaseSensitive);
  try
    while i < ArgumentCount do
    begin
      option := FArguments[i];
      if option[1] = '@' then // Process a file
      begin
        // Replace file argument in argument list to retain positional switches
        FArguments.Delete(i);
        ProcessFile(Copy(option, 2), i);
      end
      else if (i < SwitchCount) and FSwitches[i].Positional then
      begin
        { TODO : Answer question: If positional argument looks like it's a switch,
  should an exception be raised? }
        FSwitches[i].Value := option;
        Inc(i);
      end
      else
      begin
        ProcessOption(option, Names, ArgComp);
        Inc(i);
      end;
    end;
    Result := Validate;
    if (not Result) and RaiseErrors then
      ShowErrors;
  finally
    Names.Free;
    ArgComp.Free;
  end;

end;

procedure TCommandParser.ProcessOption(const AOption: string;
  const ANames: TSwitchNames; const AComparer: TArgComparer);
var
  i, j, p,
  ArgPos: integer;
  Opt,
  ArgValue: string;
  Ref: TSwitchRef;
  Ambig : boolean;

  function CheckAmbiguity(ASwitch, AOpt: string): boolean;
  begin
    Result := CompareNames(ASwitch, AOpt, FCaseSensitive) = 0;
    if Result then
      FlagUnknown(AOption);
  end;

begin
  Opt := AOption;
  if Pos(Opt[1], FSwitchChars) = 0 then
    FlagUnknown(AOption)
  else
  begin
    Opt := Copy(Opt, 2); // Skip switch
    ArgValue := '';
    ArgPos := 0;
    // Look for argument specifier
    j := Length(FArgChars);
    for i := 1 to j do
    begin
      ArgPos := Pos(FArgChars[i], Opt);
      if ArgPos > 1 then
        break; // found ArgPos
    end;

    if ArgPos > 1 then // found a value
    begin
      ArgValue := Copy(Opt, ArgPos + 1);
      Opt := Copy(Opt, 1, ArgPos - 1);
    end
    else
    begin
      j := Length(Opt);
      if Pos(Opt[j], FToggleChars) > 0 then // Found a toggle
      begin
        ArgValue := Opt[j];
        Opt := Copy(Opt, 1, j - 1);
      end;
    end;

    Ref.Name := Opt; // Set our search criteria
    { TODO : When TArray.BinarySearch is fixed, switch to using that instead }
    if not ANames.Find(Ref, i, AComparer) then // Find with partial match
      FlagUnknown(AOption)
    else
    begin
      j := Length(Opt);
      p := ANames[i].SwitchPos;
      Ambig := False;
      if CompareNames(FSwitches[p].Name, Opt, FCaseSensitive) <> 0 then
      begin
        // Short switch didn't match. Must be a long switch match.
        // Check for ambiguity
        if (i > 0) then // check above found item for another match
          Ambig := Ambig or CheckAmbiguity(Copy(ANames[i-1].Name, 1, j), Opt);
        if (i < (ANames.Count - 1)) then // check below found item for another match
          Ambig := Ambig or CheckAmbiguity(Copy(ANames[i+1].Name, 1, j), Opt);
      end;

      if not Ambig then
      begin
//        if (FSwitches[p].Kind <> stString) then
        ArgValue := NoQuote(ArgValue); // Remove bounding quotes
        if Length(ArgValue) > 0 then
          FSwitches[p].Value := ArgValue
        else if Length(FSwitches[p].Default) > 0 then
          FSwitches[p].Value := FSwitches[p].Default;
      end;
    end;
  end;
end;

function TCommandParser.SaveOptions(const AFileName: UnicodeString;
  const ALongName: Boolean): boolean;
var
  Output: TStrings;
begin
  Output := TStringList.Create;
  try
    try
      Output.Text := Options(ALongName);
      Output.SaveToFile(AFileName);
      Result := True;
    except
      Result := False;
      Raise;
    end;
  finally
    FreeAndNil(Output);
  end;
end;

procedure TCommandParser.SetSwitchChars(const Value: string);
begin
  FSwitchChars := Value;
  if Length(FSwitchChars) > 0 then
    FDefSwitch := FSwitchChars[1]
  else
    FDefSwitch := '/';

end;

procedure TCommandParser.ShowErrors;
begin
  if Length(FValidation + FUnknown) > 0 then
    Raise ECommandParser.Create(HelpText);
end;

function TCommandParser.SwitchNames: TSwitchNames;
var
  i: integer;
  Comparer: TSwitchComparer;
  Switch: TCommandSwitch;

begin
  Comparer := TSwitchComparer.Create(FCaseSensitive);
  try
    Result := TSwitchNames.Create;
    i := 0;
    for Switch in FSwitches do
    begin
      if Switch.Named then
      begin
        if Length(Switch.Name) > 0 then
          Result.Add(TSwitchRef.Create(Switch.Name, i));
        if Length(Switch.LongName) > 0 then
          Result.Add(TSwitchRef.Create(Switch.LongName, i));
      end;
      inc(i);
    end;
    Result.TrimExcess;
    Result.Sort(Comparer);
  finally
    Comparer.Free;
  end;
end;

function TCommandParser.Syntax: string;
const
  SIndent = '  ';
  SSyntax = 'Syntax:' + NL;
var
  Switch: TCommandSwitch;
  defarg: char;

begin
  if Length(FDescription) > 0 then
    Result := FDescription + NL + SSyntax
  else
    Result := SSyntax;

  defarg := FArgChars[1];
  Result := Result + SIndent + ExtractFileName( ParamStr(0) );
  for Switch in FSwitches do
    Result := Result + ' ' + Switch.SwitchSyntax(FDefSwitch);

  Result := Result + NL + 'Parameters:' + NL;
  for Switch in FSwitches do
    Result := Result + SIndent + Switch.Syntax(FDefSwitch, defarg);

end;

function TCommandParser.Validate;
var
  switch: TCommandSwitch;
  TestInt: int64;
  TestFloat: Double;
  TestDate: TDateTime;

  procedure BadFormat(AParam, AValue, AType: string);
  begin
    FValidation := FValidation + Format(StrInvalidFormat,
      [AParam, AType, AValue]);
  end;

begin
  if ArgumentCount = 0 then
  begin
    Result := True;
    exit;
  end;
  FValidation := '';
  for switch in FSwitches do
  begin
    if Switch.Required and not Switch.Assigned then
      FValidation := FValidation + Format(StrRequiredSwitch,
        [Switch.ParamName])
    else if Switch.Assigned then
      case Switch.Kind of
        stString: Switch.SetProperty(FContainer);
        stInteger:
          if not TryStrToInt64(Switch.CurrentValue, TestInt) then
            BadFormat(Switch.ParamName, Switch.CurrentValue, 'integer')
          else
            Switch.SetProperty(FContainer);

        stDate:
          if not TryStrToDate(Switch.CurrentValue, TestDate) then
            BadFormat(Switch.ParamName, Switch.CurrentValue, 'date')
          else
            Switch.SetProperty(FContainer);

        stDateTime:
          if not TryStrToDateTime(Switch.CurrentValue, TestDate) then
            BadFormat(Switch.ParamName, Switch.CurrentValue, 'datetime')
          else
            Switch.SetProperty(FContainer);

        stFloat:
          if not TryStrToFloat(Switch.CurrentValue, TestFloat) then
            BadFormat(Switch.ParamName, Switch.CurrentValue, 'float')
          else
            Switch.SetProperty(FContainer);

        stBoolean:
          if Pos(SValSep + LowerCase(Switch.CurrentValue) + SValSep,
            FFalseValues + FTrueValues) = 0 then
            BadFormat(Switch.ParamName, Switch.CurrentValue, 'boolean')
          else
            Switch.SetBoolean(FContainer, FTrueValues);

      end;
  end;
  Result := Length(FValidation + FUnknown) = 0;
end;

{ TSwitchComparer }

function TSwitchComparer.Compare(const Left, Right: TSwitchRef): Integer;
begin
  Result := CompareNames(Left.Name, Right.Name, FCaseSensitive);
end;

constructor TSwitchComparer.Create(ACaseSensitive: boolean);
begin
  inherited Create;
  FCaseSensitive := ACaseSensitive;
end;

procedure TSwitchComparer.SetCaseSensitive(const Value: boolean);
begin
  FCaseSensitive := Value;
end;

{ TArgComparer }

function TArgComparer.Compare(const Left, Right: TSwitchRef): Integer;
var
  i : integer;
begin
  i := Length(Right.Name);
  Result := CompareNames(Copy(Left.Name, 1, i), Copy(Right.Name, 1, i),
    FCaseSensitive);
end;

{ TSwitchRef }

constructor TSwitchRef.Create(const AName: string; const ASwitchPos: integer);
begin
  inherited;
  Name := AName;
  SwitchPos := ASwitchPos;
end;

{ TSwitchNames }

function TSwitchNames.Find(const Item: TSwitchRef; out FoundIndex: Integer;
  const Comparer: IComparer<TSwitchRef>; Index: Integer): Boolean;
var
  L, H: Integer;
  mid, cmp: Integer;
begin
  if Count = 0 then
  begin
    FoundIndex := 0;
    Exit(False);
  end;

  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  L := Index;
  H := Index + Count - 1;
  while L <= H do
  begin
    mid := L + (H - L) shr 1;
    cmp := Comparer.Compare(Items[mid], Item);
    if cmp < 0 then
      L := mid + 1
    else if cmp = 0 then
    begin
      FoundIndex := mid;
      Exit(True);
    end
    else
      H := mid - 1;
  end;
  FoundIndex := L;
  Result := False;
end;

function TSwitchNames.Find(const Item: TSwitchRef; out FoundIndex: Integer;
  const Comparer: IComparer<TSwitchRef>): Boolean;
begin
  Result := Find(Item, FoundIndex, Comparer, 0);
end;

{ TCommandSwitches }

destructor TCommandSwitches.Destroy;
var
  s : TCommandSwitch;
begin
  for s in Self do
    s.Free;
  inherited;
end;

end.
