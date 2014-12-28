enum TeX {
    // commands
    TOptional(tex:TeX);  // optional argument/parameter
    TCommand(cmd:String, params:Array<TeX>);  // if cmd starts with \, it must be included here!
    TEnvironment(env:String, params:Array<TeX>, contents:Array<TeX>);
    // contents
    TText(text:String);
    TRaw(raw:String);  // won't be escaped
    // containers
    TPar(tex:Array<TeX>);
    TSome(tex:Array<TeX>);
    TFile(tex:Array<TeX>);
}

