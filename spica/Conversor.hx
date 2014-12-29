package spica;

import format.simple.tex.TeX;
import format.simple.word.Document;
import spica.AuxTypes;
using Lambda;

class Conversor {

    var doc:Document;

    public function new(doc)
    {
        this.doc = doc;
    }

    function flattenProps(par:Array<Property>, run:Array<Property>):FlatProps
    {
        var flat = {
            bold : null,
            italic : null,
            fonts : null,
            style : null,
            heading : null
        };

        function _apply(weak:Bool, p:Property)
        {
            switch (p) {
            case PBold(bold) if (!weak || flat.bold == null):
                flat.bold = bold;
            case PItalic(italic) if (!weak || flat.italic == null):
                flat.italic = italic;
            case PStyleRef(style):
                flat.style = doc.styles.styles.find(function (x) return x.name == style);
            case all:
                // FIXME
                // trace('Skipping $all');
            }
        }
        var weakApply = _apply.bind(true);
        var apply = _apply.bind(false);

        // docDefaults
        doc.styles.docDefaults.parDefault.iter(apply);
        doc.styles.docDefaults.runDefault.iter(apply);

        // local props
        par.iter(apply);
        run.iter(apply);

        // styles: keep whatever has already been set
        // FIXME: this only works on very simple style definitions
        if (flat.style != null) {
            flat.style.props.iter(weakApply);
        }

        return flat;
    }

    // FIXME rename
    function deflateProps(flat:FlatProps, titlenize:Bool):Array<Mark>
    {
        if (titlenize) {
            if (flat.bold)
                flat.heading = flat.italic ? 1 : 0;  // FIXME copy first
        }

        // single marks
        if (flat.heading != null) {
            return [MHeading(flat.heading)];
        }
        // multi-marks
        var marks = [];
        if (flat.bold)
            marks.push(MBold);
        if (flat.italic)
            marks.push(MItalic);
        // FIXME the rest
        return marks;
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

    function preProcessRun(parProps, run:Run):TempRun
    {
        return switch (run.content) {
        case CText(text):
            var props = flattenProps(parProps, run.props);
            { text : text, props : props, refs : [] };
        case CFootnoteRef(id):
            { text : "", props : cast {}, refs : [id] };
        }
    }
    
    function unifiableProps(a:FlatProps, b:FlatProps):Bool {
        return a.bold == b.bold && a.italic == b.italic;  // FIXME lang
    }

    function unifyRuns(runs:Array<TempRun>):Array<TempRun>
    {
        var u = [];  // unfied runs
        var l:TempRun = null;  // last consumed run

        for (r in Reflect.copy(runs)) {
            // note: unification only possible if the previous run has no references
            if (l == null || l.refs.length > 0 || !unifiableProps(l.props, r.props)) {
                u.push(r);
                l = r;
            } else {
                l.text += r.text;
                l.refs = r.refs;
            }
        }

        return u;
    }

    function convertRun(runCnt, run:TempRun)
    {
        var props = deflateProps(run.props, runCnt == 1);
        var refs = run.refs.map(function (id) return TCommand("\\foonote", [TText('Footnote: $id')]));  // FIXME

        return if (refs.length > 0)
            applyProps(props, TSome([TText(run.text)].concat(refs)));
        else
            applyProps(props, TText(run.text));
    }

    function convertPar(par:Paragraph)
    {
        var pre = par.runs.map(preProcessRun.bind(par.props));
        var unified = unifyRuns(pre);
        return TPar(unified.map(convertRun.bind(unified.length)));
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

