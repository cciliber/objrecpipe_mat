function varargout = slider(varargin)
% SLIDER MATLAB code for slider.fig
%      SLIDER, by itself, creates a new SLIDER or raises the existing
%      singleton*.
%
%      H = SLIDER returns the handle to a new SLIDER or the handle to
%      the existing singleton*.
%
%      SLIDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLIDER.M with the given input arguments.
%
%      SLIDER('Property','Value',...) creates a new SLIDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before slider_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to slider_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help slider

% Last Modified by GUIDE v2.5 21-Apr-2015 21:41:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @slider_OpeningFcn, ...
                   'gui_OutputFcn',  @slider_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before slider is made visible.
function slider_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to slider (see VARARGIN)

% Choose default command line output for slider
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes slider wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = slider_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


    % --- Executes on slider movement.
    function slider1_Callback(hObject, eventdata, handles)
    global filename pathname SliderMax SliderMin
    
    %put slider postion value into variable k1
    k1 = get(handles.slider1,'Value');
    
    %initialise k4 so that it can be used in the if statement for the check.
    k4 = k1 + 3;


    %the if statement below is a check to make sure the value of k4 is never larger than the total
    %number of images, without some sort of check then k4 will exceed the matrix dimensions and give 
    %an error.
    if k4 > SliderMax
        k1 = SliderMax - 3;
        k2 = SliderMax - 2;
        k3 = SliderMax - 1;
        k4 = SliderMax;  
    else
        k1 = floor(k1);
        k2 = k1 + 1;
        k3 = k1 + 2;
        k4 = k1 + 3;
    end
    
    
    %generating of strings containing the full path to the that will be displayed.
    img1 = strcat(pathname, filename{k1});
    img2 = strcat(pathname, filename{k2});
    img3 = strcat(pathname, filename{k3});
    img4 = strcat(pathname, filename{k4});
    
    
    %assign an axes handle to preceed imshow and use imshow to display the images
    % in individual axes.
    axes(handles.axes1);
    imshow(img1);
    
    axes(handles.axes6);
    imshow(img2);
    
    axes(handles.axes7);
    imshow(img3);
    
    axes(handles.axes8);
    imshow(img4);


    % --- Executes on button press in pushbutton1.
    function pushbutton1_Callback(hObject, eventdata, handles)
    %global variables allow sharing of variables between functions
    global filename pathname k1 SliderMax SliderMin
    
     %multi-file selection
    [filename, pathname, ~] = uigetfile({  '*.jpg'}, 'Pick files',...
    'MultiSelect', 'on');
    
    %determine the maximum value the slider can be. this value is based on the number of files selected
    %the min value will be set to 1
    SliderMax = length(filename)
    SliderMin = 1;
    set(handles.slider1,'Max',SliderMax);
    set(handles.slider1,'Min',SliderMin);
    
    %initialise k1 (slider position) since 4 images will be shown k1 needs to be incremented so you show 
    %4 different images
    k1 = 1;
    k2 = k1 + 1;
    k3 = k1 + 2;
    k4 = k1 + 3;
    
    %generating of strings containing the full path to the that will be displayed.
    img1 = strcat(pathname, filename{k1});
    img2 = strcat(pathname, filename{k2});
    img3 = strcat(pathname, filename{k3});
    img4 = strcat(pathname, filename{k4});
    
    
    %assign an axes handle to preceed imshow and use imshow to display the images
    % in individual axes.
    axes(handles.axes1);
    imshow(img1);
    
    axes(handles.axes6);
    imshow(img2);
    
    axes(handles.axes7);
    imshow(img3);
    
    axes(handles.axes8);
    imshow(img4);

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
