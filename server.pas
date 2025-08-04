program HTTPServer;

uses System, System.Net, System.IO, System.Text;

type
  // Event record for storing bubble sort steps
  TEvent = record
    action: string;
    step: integer;
    compare_idx1, compare_idx2: integer;
    compare_val1, compare_val2: integer;
    swap_idx1, swap_idx2: integer;
    swap_val1, swap_val2: integer;
    array_state: string;
    is_swap: boolean;
  end;

var
  arr: array of integer;
  events: array of TEvent;
  listener: HttpListener;
  step_counter: integer;

// Adds a new event to the event log
procedure AddEvent(action_type: string; idx1, idx2, val1, val2: integer; is_swap_action: boolean);
var
  currentEvent: TEvent;
  i: integer;
  array_json: string;
begin
  array_json := '[';
  for i := 0 to Length(arr) - 1 do
  begin
    array_json += arr[i].ToString();
    if i < Length(arr) - 1 then
      array_json += ', ';
  end;
  array_json += ']';

  currentEvent.action := action_type;
  currentEvent.step := step_counter;
  currentEvent.compare_idx1 := idx1;
  currentEvent.compare_idx2 := idx2;
  currentEvent.compare_val1 := val1;
  currentEvent.compare_val2 := val2;

  if is_swap_action then
  begin
    currentEvent.swap_idx1 := idx1;
    currentEvent.swap_idx2 := idx2;
    currentEvent.swap_val1 := val2;
    currentEvent.swap_val2 := val1;
  end
  else
  begin
    currentEvent.swap_idx1 := -1;
    currentEvent.swap_idx2 := -1;
    currentEvent.swap_val1 := -1;
    currentEvent.swap_val2 := -1;
  end;

  currentEvent.is_swap := is_swap_action;
  currentEvent.array_state := array_json;

  SetLength(events, Length(events) + 1);
  events[Length(events) - 1] := currentEvent;
  Inc(step_counter);
end;

// Performs bubble sort and logs steps
procedure BubbleSort();
var
  i, j, temp: integer;
  swapped: boolean;
begin
  step_counter := 0;
  SetLength(events, 0);
  AddEvent('init', -1, -1, -1, -1, false);

  for i := 0 to Length(arr) - 2 do
  begin
    swapped := false;
    for j := 0 to Length(arr) - 2 - i do
    begin
      AddEvent('compare', j, j + 1, arr[j], arr[j + 1], false);

      if arr[j] > arr[j + 1] then
      begin
        temp := arr[j];
        arr[j] := arr[j + 1];
        arr[j + 1] := temp;
        swapped := true;

        AddEvent('swap', j, j + 1, arr[j + 1], arr[j], true);
      end;
    end;

    if not swapped then
      break;
  end;

  AddEvent('finished', -1, -1, -1, -1, false);
end;

// Generates JSON array of all events
function CreateEventsJSON(): string;
var
  i: integer;
  json: string;
begin
  json := '[';
  for i := 0 to Length(events) - 1 do
  begin
    json += '{';
    json += '"action": "' + events[i].action + '", ';
    json += '"step": ' + events[i].step.ToString() + ', ';
    json += '"compare_indices": [' + events[i].compare_idx1.ToString() + ', ' + events[i].compare_idx2.ToString() + '], ';
    json += '"compare_values": [' + events[i].compare_val1.ToString() + ', ' + events[i].compare_val2.ToString() + '], ';
    json += '"swap_indices": [' + events[i].swap_idx1.ToString() + ', ' + events[i].swap_idx2.ToString() + '], ';
    json += '"swap_values": [' + events[i].swap_val1.ToString() + ', ' + events[i].swap_val2.ToString() + '], ';
    json += '"is_swap": ' + (if events[i].is_swap then 'true' else 'false') + ', ';
    json += '"array_state": ' + events[i].array_state + '}';

    if i < Length(events) - 1 then
      json += ', ';
  end;
  json += ']';
  Result := json;
end;

// Handles HTTP requests
procedure HandleRequest(context: HttpListenerContext);
var
  request: HttpListenerRequest;
  response: HttpListenerResponse;
  responseString: string;
  buffer: array of byte;
  url_path: string;
  reader: StreamReader;
  postData, arrayStr: string;
  numbers: array of string;
  i: integer;
begin
  request := context.Request;
  response := context.Response;
  url_path := request.Url.AbsolutePath;

  response.Headers.Add('Access-Control-Allow-Origin', '*');
  response.Headers.Add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.Headers.Add('Access-Control-Allow-Headers', 'Content-Type');

  if request.HttpMethod = 'OPTIONS' then
  begin
    response.StatusCode := 200;
    response.Close();
    exit;
  end;

  if url_path = '/sort' then
  begin
    if request.HttpMethod = 'POST' then
    begin
      reader := new StreamReader(request.InputStream);
      postData := reader.ReadToEnd();
      arrayStr := postData.Replace('{', '').Replace('}', '').Replace('"array":', '').Replace('[', '').Replace(']', '').Trim();
      numbers := arrayStr.Split(',');

      SetLength(arr, Length(numbers));
      for i := 0 to Length(numbers) - 1 do
        arr[i] := StrToInt(numbers[i].Trim());

      BubbleSort();

      responseString := CreateEventsJSON();
      response.ContentType := 'application/json; charset=utf-8';
      response.StatusCode := 200;
    end
    else
    begin
      responseString := '{"error": "Method not allowed"}';
      response.StatusCode := 405;
    end;
  end
  else if url_path = '/test' then
  begin
    arr := [64, 34, 25, 12, 22, 11, 90];
    BubbleSort();
    responseString := CreateEventsJSON();
    response.ContentType := 'application/json; charset=utf-8';
    response.StatusCode := 200;
  end
  else
  begin
    responseString := '{"error": "Not found", "endpoints": ["/sort", "/test"]}';
    response.StatusCode := 404;
  end;

  buffer := Encoding.UTF8.GetBytes(responseString);
  response.ContentLength64 := Length(buffer);
  response.OutputStream.Write(buffer, 0, Length(buffer));
  response.Close();
end;

// Program entry point
begin
  WriteLn('HTTP server for bubble sort visualization is starting...');
  WriteLn('Access at: http://localhost:8080/');
  WriteLn('Available endpoints:');
  WriteLn('  GET  /test');
  WriteLn('  POST /sort');

  try
    listener := new HttpListener();
    listener.Prefixes.Add('http://localhost:8080/');
    listener.Start();

    WriteLn('Server started. Press Ctrl+C to stop.');

    while true do
    begin
      try
        var context: HttpListenerContext;
        context := listener.GetContext();
        HandleRequest(context);
      except
        on e: Exception do
          WriteLn('Error handling request: ' + e.Message);
      end;
    end;
  except
    on e: Exception do
    begin
      WriteLn('Failed to start server: ' + e.Message);
      WriteLn('Ensure port 8080 is available.');
    end;
  end;

  if listener <> nil then
  begin
    listener.Stop();
    listener.Close();
  end;

  WriteLn('Server stopped.');
end.
