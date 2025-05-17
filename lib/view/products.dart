import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:front/viewmodel/product_view_model.dart';
import 'package:front/viewmodel/workflow_view_model.dart';
import 'package:photo_view/photo_view.dart';
import '../model/workflow.dart';
import '../model/product.dart';
import 'model_3d_viewer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  late WorkflowViewModel workflowViewModel;
  late ProductViewModel productViewModel;
  List<Workflow> workflowsdata = [];
  bool isLoading = true;
  Map<int, Product?> productsCache = {};
    static List<Workflow>? _cachedWorkflows;
  static Map<int, Product?> _cachedProducts = {};
  static bool _isCacheValid = false;
  @override
  void initState() {
    super.initState();
    workflowViewModel = WorkflowViewModel();
    productViewModel = ProductViewModel();
    _loadData();
  }

 Future<void> _loadData({bool forceRefresh = false}) async {
  // Use cached data if available and not forcing refresh
  if (!forceRefresh && _isCacheValid && _cachedWorkflows != null) {
    setState(() {
      workflowsdata = _cachedWorkflows!;
      productsCache = Map.from(_cachedProducts); // Copy cached products
      isLoading = false;
    });
    return;
  }

  setState(() => isLoading = true);
  
  try {
    final workflows = await workflowViewModel.fetchAllWorkflows();
    // Update cache
    _cachedWorkflows = workflows;
    _cachedProducts = {};
    _isCacheValid = true;
    
    setState(() {
      workflowsdata = workflows;
      isLoading = false;
    });
    
    // Preload products for each workflow
    for (var workflow in workflows) {
      if (workflow.product_id != null) {
        await _loadProduct(workflow.product_id!, forceRefresh: forceRefresh);
      }
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    // If we have cached data, show it even if refresh failed
    if (_cachedWorkflows != null) {
      setState(() {
        workflowsdata = _cachedWorkflows!;
        productsCache = Map.from(_cachedProducts);
      });
    }
  }
}

  void _show2dBlueprintPopup(Uint8List imageBytes) {
    final intl = AppLocalizations.of(context)!;
  try {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title:  Text(intl.twoDBlueprint),
            backgroundColor: const Color(0xFFB5927F),
          ),
          body: PhotoView(
            imageProvider: MemoryImage(imageBytes),
            minScale: PhotoViewComputedScale.contained * 0.5,
            maxScale: PhotoViewComputedScale.covered * 3.0,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: 'image_${DateTime.now().millisecondsSinceEpoch}'),
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to display image: ${e.toString()}')),
    );
  }
}
void _invalidateCache() {
  _isCacheValid = false;
  _cachedWorkflows = null;
  _cachedProducts.clear();
  productsCache.clear();
}
Future<void> _loadProduct(int productId, {bool forceRefresh = false}) async {
  if (!forceRefresh && _cachedProducts.containsKey(productId)) {
    setState(() {
      productsCache[productId] = _cachedProducts[productId];
    });
    return;
  }

  final product = await productViewModel.getProductById(productId.toString());
  // Update both local and cached products
  setState(() {
    productsCache[productId] = product;
    _cachedProducts[productId] = product;
  });
}

  void _show3dModelPopup(String modelPath) {
    final intl = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(intl.threeDModelPreview),
            backgroundColor: const Color(0xFFB5927F),
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
          ),
          body: ProductObject(modelpath: modelPath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      final intl = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB5927F),
        title:  Padding(
          padding: EdgeInsets.only(left: 120),
          child: Text(
            intl.productList,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4e3a31).withOpacity(0.7),
              fontFamily: 'BrandonGrotesque',
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: const Color(0xFF4e3a31).withOpacity(.70),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB5927F),
              ),
            )
          : workflowsdata.isEmpty
              ?  Center(
                  child: Text(
                    intl.noWorkflows,
                    style: TextStyle(
                      color: Color(0xFF4e3a31),
                      fontSize: 18,
                    ),
                  ),
                )
              : RefreshIndicator(
                onRefresh: () => _loadData(forceRefresh: true),
                color: const Color(0xFFB5927F),
                child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workflowsdata.length,
                    itemBuilder: (context, index) {
                      final workflow = workflowsdata[index];
                      final product = workflow.product_id != null 
                          ? productsCache[workflow.product_id!]
                          : null;
                      
                      // Simple image decoding like your user example
                      Uint8List? imageBytes;
                      if (workflow.image != null && workflow.image!.isNotEmpty) {
                        try {
                          imageBytes = base64Decode(workflow.image!);
                        } catch (_) {}
                      }
              
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: const Color(0xFFB5927F).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        shadowColor: const Color(0xFF4e3a31).withOpacity(0.1),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFDF8F4),
                                const Color(0xFFFBEFE8).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Workflow Header Section
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5E6DC).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFB5927F).withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFFB5927F).withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.work_outline,
                                        size: 40,
                                        color: Color(0xFF4e3a31),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              workflow.name ?? intl.unamedWorkflow,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF4e3a31),
                                                fontFamily: 'BrandonGrotesque',
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Status: ${_getStatusText(workflow.status_id)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _getStatusColor(workflow.status_id),
                                                fontFamily: 'BrandonGrotesque',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Product Information Section
                                if (product != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         Text(
                                          intl.associatedProduct,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4e3a31),
                                            fontFamily: 'BrandonGrotesque',
                                            fontSize: 16,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name ?? intl.unamedProduct,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'BrandonGrotesque',
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            // 3D Model Button (on top)
                                            if (product.modelFileName != null && product.modelFileName!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Tooltip(
                                                  message: workflow.status_id != 3 
                                                      ? intl.onlyAvailable 
                                                      : intl.viewModel,
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      icon: const Icon(Icons.threed_rotation, size: 16),
                                                      label:  Text(intl.viewModel),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: workflow.status_id == 3 
                                                            ? const Color(0xFFB5927F)
                                                            : const Color(0xFFB5927F).withOpacity(0.5),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                                      ),
                                                      onPressed: workflow.status_id == 3 
                                                          ? () => _show3dModelPopup(product.modelFileName!)
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            // 2D Blueprint Button (below) - SIMPLE VERSION
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.image, size: 16),
                                                label:  Text(intl.viewBlueprint),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF78A190),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onPressed: imageBytes != null 
                                                    ? () => _show2dBlueprintPopup(imageBytes!)
                                                    : null,
                                              ),
                                            ),
                                            if (workflow.image != null && imageBytes == null)
                                               Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  intl.invalidImageFormat,
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                   Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      intl.noAssociatedProduct,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ),
    );
  }

  Color _getStatusColor(int? statusId) {
    switch (statusId) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(int? statusId) {
    switch (statusId) {
      case 1: return 'Created';
      case 2: return 'Started';
      case 3: return 'Finished';
      default: return 'Unknown';
    }
  }
}
