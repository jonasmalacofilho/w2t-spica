using Lambda;

class Writer {

    var buf : StringBuf;

    function new()
    {
        reset();
    }

    function reset()
    {
        buf = new StringBuf();
    }

    function toString()
    {
        return buf.toString();
    }

    function writeParam(tex:TeX)
    {
        switch (tex) {
        case TOptional(one):
            buf.add("[");
            writeTeX(one);
            buf.add("}");
        case _:
            buf.add("{");
            writeTeX(tex);
            buf.add("}");
        }
    }

    function writeTeX(tex:TeX)
    {
        switch (tex) {
        case TFile(several), TSome(several): several.iter(writeTeX);
        case TPar(several):
            several.iter(writeTeX);
            buf.add("\n\n");
        case TRaw(raw): buf.add(raw);
        case TText(text): buf.add(text);  // FIXME must escape!!
        case TCommand(cmd, params):
            buf.add(cmd);
            params.iter(writeParam);
        case TOptional(one):
            throw 'Assert: $tex';
        case all: // FIXME
        }
    }

    public static function write(tex:TeX):String
    {
        var r = new Writer();
        r.writeTeX(tex);
        return r.toString();
    }

}

