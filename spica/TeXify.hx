import Writer.write;
import Sys.println;
import format.simple.word.DocxReader.readDocx;

class TeXify {

    static function transform(doc)
    {
        // TODO
        return doc;
    }

    public static function main()
    {
        var doc = readDocx(Sys.stdin());
        var trans = transform(doc);
        var tex = write(trans);
        println(tex);
    }

}

