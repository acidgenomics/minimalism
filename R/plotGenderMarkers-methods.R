#' @include plotCounts-methods.R



#' @name plotGenderMarkers
#' @inherit bioverbs::plotGenderMarkers
#' @inheritParams plotCounts
#' @inheritParams params
#'
#' @note Currently only *Homo sapiens* and *Mus musculus* genomes are supported.
NULL



#' @importFrom bioverbs plotGenderMarkers
#' @aliases NULL
#' @export
bioverbs::plotGenderMarkers



plotGenderMarkers.SummarizedExperiment <-  # nolint
    function() {
        validObject(object)

        # Load the relevant internal gender markers data.
        organism <- organism(object)
        data("gender_markers", package = "basejump", envir = environment())
        markers <- get("gender_markers", inherits = FALSE)
        assert(is.list(markers))
        # Error if the organism is not supported.
        # Convert from camel case back to full Latin.
        supportedOrganisms <- names(markers) %>%
            snake() %>%
            sub("^([a-z])", "\\U\\1", ., perl = TRUE) %>%
            sub("_", " ", .)
        if (!organism %in% supportedOrganisms) {
            stop(paste0(
                organism, " is not supported.\n",
                "Supported organisms: ",
                toString(supportedOrganisms)
            ))
        }
        markers <- markers[[camel(organism)]]
        assert(is(markers, "tbl_df"))

        # Message the user instead of erroring, since many datasets don't
        # contain the dimorphic gender markers.
        genes <- tryCatch(
            expr = mapGenesToRownames(
                object = object,
                genes = markers[["geneID"]]
            ),
            error = function(e) {
                message(as.character(e))
                character()
            }
        )
        if (length(genes) == 0L) {
            return(invisible())
        }

        do.call(
            what = plotCounts,
            args = matchArgsToDoCall(
                args = list(genes = genes)
            )
        )
    }

f <- formals(plotCounts.SummarizedExperiment)
f <- f[setdiff(names(f), "genes")]
f[["style"]] <- "wide"
formals(plotGenderMarkers.SummarizedExperiment) <- f



#' @rdname plotGenderMarkers
#' @export
setMethod(
    f = "plotGenderMarkers",
    signature = signature("SummarizedExperiment"),
    definition = plotGenderMarkers.SummarizedExperiment
)



#' @rdname plotGenderMarkers
#' @usage NULL
#' @export
setMethod(
    f = "plotGenderMarkers",
    signature = signature("SingleCellExperiment"),
    definition = function(object, ...) {
        stop("SingleCellExperiment is not currently supported.")
    }
)