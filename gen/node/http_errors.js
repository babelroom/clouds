
function _internal_error(res, code, text)
{
    res.statusCode = code;
    switch(code) {
        case 500:
            console.log('_internal_error', code, res);
        }
    var data = JSON.stringify({error: {code: code, text: text}});
/*    res.setHeader('Content-Length', data.length); seems not to be needed */
    try {
        res.send(data);
        res.end();
        }
    catch(err) { console.log(err); }
}

function _ok_maybe_redirect(req, res, result)
{
    /* for form data, multiple different content types, not sure what req.is() returns, expect it's good but do this to be safe */
    if ((!req.headers['content-type'] || !req.is('json')) && req.body._success_url) {
        res.redirect(req.body._success_url);
        }
    else {
        res.send(result);
        res.end();
        }
}

var httpErrors = {
    foo: 'bar'

    , bad: function(res, text) { return _internal_error(res, 400, text?text:'Bad Request'); }
    , unauthorized: function(res) { /* not used much as session manager is opaque as to whether any auth existed (403) or not (401) */
        res.setHeader('WWW-Authenticate', 'Basic realm="brapiv1"');
        return _internal_error(res, 401, 'HTTP Basic Auth or Cookie Session Required');
        }
    , forbidden: function(res) { return _internal_error(res, 403, 'Access Denied'); }
    , not_found: function(res) { return _internal_error(res, 404, 'Not Found'); }
    , internal_server_error: function(res) { return _internal_error(res, 500, 'Internal Server Error'); }
    , not_implemented: function(res) { return _internal_error(res, 501, 'Not implemented'); }
    , db_error: function(res, err, sql) {
        console.log('DB error: ' + err + "\nSQL[" + sql + ']');
        if (err && err.code=='ECONNREFUSED')
            return _internal_error(res, 503, 'Service Temporarily Unavailable');
        else
            return httpErrors.internal_server_error(res);
        }
    , code: function(res, code) {
        switch(code) {
            /* don't have to do them all */
            case 400: return httpErrors.bad(res);
            case 401: return httpErrors.unauthorized(res);
            case 403: return httpErrors.forbidden(res);
            case 404: return httpErrors.not_found(res);
            case 500: return httpErrors.internal_server_error(res);
            default:
                return httpErrors._internal_error(res, code);
            }
        }
    , ok: _ok_maybe_redirect,
}

module.exports = httpErrors;

