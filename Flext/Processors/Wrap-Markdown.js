const calculate_indent = function(line, current_indent) {
    if (line.length == 0) { return "" }
    if (current_indent.length != 0 && line.startsWith(current_indent)) { return current_indent }
    
    const re = /\A[ ]*(?:(?:[\d]+\.)|(?:[*-]))[ ]+/
    const match = line.match(re)

    if (match == null) {
        return ""
    } else {
        return match[0].length
    }
}

const process_line = function(line, wrap_limit, indent, pos = 0) {
    var result = ""
    var current_pos = pos
    var prev_newline_pos = pos
    
    const words = line.split(" ")

    for (const word of words) {
        if (current_pos + word.length > wrap_limit) {
            prev_newline_pos = result.length
            result = result + "\n" + indent + word
        } else if (current_pos != 0) {
            result = result + " " + word
        } else {
            result = result + word
        }
        current_pos = result.length - prev_newline_pos
    }

    return result
}

var process = function(text, wrap_limit = 72 /* The maximum number of characters to display before wrapping */) {
    const chunk_re = /([^\n]+)|([\n]+)/g
    const list_start_re = /^(?:\d+\.|[-*]+) +/
    const code_start_re = /^[ ]{4,}/
    
    var result = ""
    var indent = ""
    var list_start = null
    var is_new_block = true
    var is_fenced_code = false
    var is_indented_code = false
    var is_item_list = false

    const chunks = text.match(chunk_re)
    
    for (const chunk of chunks) {
        if (is_fenced_code) {
            result = result + chunk
            if (chunk == "~~~") {
                is_fenced_code = false
            }
        } else if (is_indented_code) {
            result = result + chunk
            if (chunk.startsWith("\n\n")) {
                is_indented_code = false
            }
        } else if (chunk == "\n") {
            continue
        } else if (chunk.startsWith("\n\n")) {
            result = result + chunk
            is_new_block = true
            is_indented_code = false
            is_item_list = false
        } else if (chunk == "~~~") {
            result = result + chunk
            is_new_block = false
            is_fenced_code = true
        } else if (chunk.match(code_start_re) != null) {
            result = result + chunk
            is_new_block = false
            is_indented_code = true
        } else if ((list_start = chunk.match(list_start_re)) != null) {
            indent = " ".repeat(list_start[0].length)
            result = result + process_line(chunk, wrap_limit, indent)
            is_new_block = false
            is_item_list = true
        } else if (is_item_list) {
            const first_non_space = chunk.match(/[^ ]/)
            if (first_non_space != null) {
                indent = " ".repeat(first_non_space.index)
                var last_newline = result.lastIndexOf("\n")
                result = result + process_line(chunk.slice(first_non_space.index), wrap_limit, indent, result.length - last_newline)
            }
            is_new_block = false
        } else {
            if (!chunk.startsWith(indent)) {
                indent = ""
            }
            result = result + process_line(chunk, wrap_limit, indent)
            is_new_block = false
        }
    }
    
    return result
}
