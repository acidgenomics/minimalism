#' @name plotCountsPerCell
#' @author Michael Steinbaugh, Rory Kirchner
#' @include globals.R
#' @inherit bioverbs::plotCountsPerCell
#' @note Updated 2019-08-08.
#'
#' @inheritParams acidroxygen::params
#' @param point `character(1)`.
#'   Label either the "`knee`" or "`inflection`" points per sample. To disable,
#'   use "`none`". Requires `geom = "ecdf"`.
#' @param ... Additional arguments.
#'
#' @examples
#' data(SingleCellExperiment, package = "acidtest")
#'
#' ## SingleCellExperiment ====
#' object <- SingleCellExperiment
#' object <- calculateMetrics(object)
#' plotCountsPerCell(object, geom = "violin")
#' plotCountsPerCell(object, geom = "ridgeline")
#' plotCountsPerCell(object, geom = "ecdf")
#' plotCountsPerCell(object, geom = "histogram")
#' plotCountsPerCell(object, geom = "boxplot")
NULL



#' @rdname plotCountsPerCell
#' @name plotCountsPerCell
#' @importFrom bioverbs plotCountsPerCell
#' @usage plotCountsPerCell(object, ...)
#' @export
NULL



## Updated 2019-07-24.
`plotCountsPerCell,SingleCellExperiment` <-  # nolint
    function(
        object,
        geom,
        interestingGroups = NULL,
        min = 0L,
        max = Inf,
        point = c("none", "inflection", "knee"),
        trans = "log10",
        color,
        fill,
        title = "Counts per cell"
    ) {
        assert(isString(title, nullOK = TRUE))
        geom <- match.arg(geom)
        point <- match.arg(point)

        ## Override `interestingGroups` argument when labeling points.
        if (point != "none") {
            interestingGroups <- "sampleName"
        }

        p <- do.call(
            what = .plotQCMetric,
            args = list(
                object = object,
                ## Note that this was changed in v0.3.19 to better match
                ## conventions used in Chromium and Seurat packages.
                metricCol = "nCount",
                geom = geom,
                interestingGroups = interestingGroups,
                min = min,
                max = max,
                trans = trans,
                color = color,
                fill = fill
            )
        )

        ## Calculate barcode ranks and label inflection or knee points.
        if (point != "none") {
            ## Require ecdf geom for now
            assert(identical(geom, "ecdf"))

            if (length(title)) {
                p <- p + labs(subtitle = paste(point, "point per sample"))
            }

            sampleNames <- sampleNames(object)

            ranks <- barcodeRanksPerSample(object)
            ## Inflection or knee points per sample.
            points <- lapply(
                X = ranks,
                FUN = function(x) {
                    assert(is(x, "DataFrame"))
                    out <- metadata(x)[[point]]
                    assert(is.numeric(out))
                    out
                }
            )
            points <- unlist(points)
            names(points) <- names(ranks)

            assert(identical(names(sampleNames), names(points)))

            if (geom == "ecdf") {
                ## Calculate the y-intercept per sample.
                freq <- mapply(
                    sampleID = names(points),
                    point = points,
                    MoreArgs = list(metrics = metrics(object)),
                    FUN = function(metrics, sampleID, point) {
                        nCount <- metrics[
                            metrics[["sampleID"]] == sampleID,
                            "nCount",
                            drop = TRUE
                        ]
                        e <- ecdf(sort(nCount))
                        e(point)
                    },
                    SIMPLIFY = TRUE,
                    USE.NAMES = TRUE
                )
                pointData <- data.frame(
                    x = points,
                    y = freq,
                    label = paste0(sampleNames, " (", points, ")"),
                    sampleName = sampleNames
                )
                p <- p +
                    geom_point(
                        data = pointData,
                        mapping = aes(
                            x = !!sym("x"),
                            y = !!sym("y"),
                            color = !!sym("sampleName")
                        ),
                        size = 5L,
                        show.legend = FALSE
                    ) +
                    acid_geom_label_repel(
                        data = pointData,
                        mapping = aes(
                            x = !!sym("x"),
                            y = !!sym("y"),
                            label = !!sym("label"),
                            color = !!sym("sampleName")
                        )
                    )
            }
        }

        p <- p + labs(title = title)

        p
    }

formals(`plotCountsPerCell,SingleCellExperiment`)[c("color", "fill")] <-
    formalsList[c("color.discrete", "fill.discrete")]
formals(`plotCountsPerCell,SingleCellExperiment`)[["geom"]] <- geom



#' @rdname plotCountsPerCell
#' @export
setMethod(
    f = "plotCountsPerCell",
    signature = signature("SingleCellExperiment"),
    definition = `plotCountsPerCell,SingleCellExperiment`
)