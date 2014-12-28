import format.simple.word.Document;
using Lambda;

class Writer {

    var doc:Document;

    public function new(doc)
    {
        this.doc = doc;
    }

    function getFootnote(id)
    {
        // FIXME
        return null;
    }

    function writeFootnote(fnote)
    {
        // FIXME
        return "";
    }

    function writeRun(run)
    {
        return switch (run.content) {
        case CText(text): text;
        case CFootnoteRef(id): '\\footnote{Footnote: $id}';  // FIXME
        }
    }

    function writePar(par)
    {
        return par.runs.map(writeRun).join("");
    }

    function writeBody(body)
    {
        function f(p)
            return p.length > 0;

        return body.pars.map(writePar).filter(f).join("\n\n");
    }

    public function writeDoc()
    {
        return writeBody(doc.body);
    }

    public static function write(doc:Document):String
    {
        var r = new Writer(doc);
        return r.writeDoc();
    }

}

