package spica;

import format.simple.word.Document;

// Formating pipeline: Array<(Document).Property> -> FlatProps -> Array<Marks>

typedef FlatProps = {
    bold : Null<Bool>,
    italic : Null<Bool>,
    fonts : Null<Int>,  // FIXME
    style : Null<Style>,
    heading : Null<Int>
}

enum Mark {
    MBold;
    MItalic;
    MHeading(sublevel:Int); // 0, 1, 2, 3
    // FIXME the rest
}

// Run conversion pipeline: (Document).Run -> TempRun -> TeX

typedef TempRun = {
    text : String,
    props : Null<FlatProps>,
    refs : Array<Int>
}

