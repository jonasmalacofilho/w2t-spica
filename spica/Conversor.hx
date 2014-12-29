import TeX;
import format.simple.word.Document;
using Lambda;

enum Mark {
    MBold;
    MItalic;
    MHeading(sublevel:Int); // 0, 1, 2, 3
    // FIXME the rest
}

class Conversor {

    var doc:Document;
    var _parProps:Array<Property>;

    public function new(doc)
    {
        this.doc = doc;
    }

    function flattenProps(par:Array<Property>, run:Array<Property>)
    {
        var flat = {
            bold : null,
            italic : null,
            fonts : null,
            style : null,
            heading : null
        };

        function apply(p:Property)
        {
            switch (p) {
            case PBold(bold):
                flat.bold = bold;
            case PItalic(italic):
                flat.italic = italic;
            case PStyleRef(style):
                flat.style = doc.styles.styles.find(function (x) return x.name == style);
            case all:
                // FIXME
                trace('Skipping $all');
            }
        }

        // docDefaults
        doc.styles.docDefaults.parDefault.iter(apply);
        doc.styles.docDefaults.runDefault.iter(apply);

        // TODO styles
        if (flat.style != null) {
            flat.style.props.iter(apply);
        }
        
        // local props
        par.iter(apply);
        run.iter(apply);

        // back to Array<Property>
        var ret = [];
        // sigle marks
        if (flat.heading != null) {
            ret.push(MHeading(flat.heading));
            return ret;
        }
        // multi-marks
        if (flat.bold)
            ret.push(MBold);
        if (flat.italic)
            ret.push(MItalic);
        // FIXME the rest
        return ret;
    }

    function applyProps(flat:Array<Mark>, tex:TeX)
    {
        if (flat.length == 0)
            return tex;

        switch (flat.shift()) {  // FIXME don't change flat in-place
        case MBold:
            tex = TCommand("\\manuscriptbf", [tex]);
        case MItalic:
            tex = TCommand("\\manuscriptit", [tex]);
        case MHeading(0):
            tex = TCommand("\\chapter", [tex]);
        case MHeading(sublevel):
            var cname = "section";
            for (i in 1...sublevel)
                cname = "sub" + cname;
            tex = TCommand('\\$cname', [tex]);
        case all:
            // FIXME
            trace('Skipping $all');
        }

        return applyProps(flat, tex);
    }

    function getFootnote(id)
    {
        // FIXME
        return null;
    }

    function convertFootnote(fnote)
    {
        // FIXME
        return "";
    }

    function convertRun(run:Run)
    {
        return switch (run.content) {
        case CText(text):
            var props = flattenProps(_parProps, run.props);
            applyProps(props, TText(text));
        case CFootnoteRef(id):
            TCommand("\\footnote", [TText('Footnote: $id')]);  // FIXME
        }
    }

    function convertPar(par:Paragraph)
    {
        _parProps = par.props;
        return TPar(par.runs.map(convertRun));
    }

    function convertBody(body:Body)
    {
        function f(p:TeX)
            return !p.match(TPar([]));

        return TSome(body.pars.map(convertPar).filter(f));
    }

    public function convertDoc()
    {
        return convertBody(doc.body);
    }

    public static function convert(doc:Document):TeX
    {
        var r = new Conversor(doc);
        return r.convertDoc();
    }

}

