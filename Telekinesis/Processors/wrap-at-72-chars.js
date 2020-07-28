var process_line = function(line) {
    result = ""
    current_pos = 0
    prev_newline_pos = 0
    wrap_limit = 72
    words = line.split(" ")

    for (const word of words) {
        if (current_pos + word.length > wrap_limit) {
            prev_newline_pos = result.length
            result = result + "\n" + word
        } else if (current_pos != 0) {
            result = result + " " + word
        } else {
            result = result + word
        }
        current_pos = result.length - prev_newline_pos
    }

    return result
}

var process = function(text) {
    result = ""
    lines = text.split("\n")
    
    for (const line of lines) {
        result = result + process_line(line) + "\n"
    }
    
    return result
}
