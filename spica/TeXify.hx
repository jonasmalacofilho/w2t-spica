package spica;

import Sys.println;
import format.simple.tex.Writer.write;
import format.simple.word.DocxReader.readDocx;
import spica.Conversor.convert;

class TeXify {

    static function transform(doc)
    {
        // TODO
        return doc;
    }

    public static function main()
    {
        haxe.Log.trace = function (m, ?p)
            Sys.stderr().writeString('${p.fileName}:${p.lineNumber}: $m\n');

        var doc = readDocx(Sys.stdin());
        // trace(doc);

        var tex = convert(doc);

        var text = write(tex);

        println(text);
    }

}

