package format.simple.word;

// Properties ...

// paragraph and run properties (TODO others)
enum Property {
    PBold(bold:Bool);
    PItalic(italic:Bool);
    PFonts(ascii:Null<String>, hAnsi:Null<String>, cs:Null<String>, eastAsia:Null<String>);
    PStyleRef(name:String);
}

typedef Style = {
    name : String,
    basedOn : Null<String>,
    props : Array<Property>,
}

typedef DocDefaults = {
    parDefault : Array<Property>,
    runDefault : Array<Property>
}

// Stories ...

enum RunContent {
    CText(text:String);
    CFootnoteRef(id:Int);
}

typedef Run = {
    props : Array<Property>,
    content : RunContent
}

typedef Paragraph = {
    props : Array<Property>,
    runs : Array<Run>
}

typedef Body = {
    pars : Array<Paragraph>
}

// Top level ...

typedef Styles = {
    docDefaults : DocDefaults,
    styles : Array<Style>
}

typedef Document = {
    styles : Styles,
    body : Body
}

