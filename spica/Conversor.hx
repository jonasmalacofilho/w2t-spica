import TeX;
import format.simple.word.Document;
using Lambda;

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
            style : null
        };

        function apply(p:Property)
        {
            switch (p) {
            case PBold(bold):
                flat.bold = bold;
            case PItalic(italic):
                flat.italic = italic;
            case all:
                // FIXME
                trace('Skipping $all');
            }
        }

        // docDefaults
        doc.styles.docDefaults.parDefault.iter(apply);
        doc.styles.docDefaults.runDefault.iter(apply);

        // TODO styles
        
        // local props
        par.iter(apply);
        run.iter(apply);

        // back to Array<Property>
        var ret = [];
        if (flat.bold)
            ret.push(PBold(true));
        if (flat.italic)
            ret.push(PItalic(true));
        // FIXME the rest
        return ret;
    }

    function applyProps(flat:Array<Property>, tex:TeX)
    {
        if (flat.length == 0)
            return tex;

        switch (flat.shift()) {  // FIXME don't change flat in-place
        case PBold(true):
            tex = TCommand("\\manuscriptbf", [tex]);
        case PItalic(true):
            tex = TCommand("\\manuscriptit", [tex]);
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

