import 'package:flutter/material.dart';
import 'package:front/viewmodel/product_view_model.dart';
import 'package:front/viewmodel/workflow_view_model.dart';
import '../model/workflow.dart';
import '../model/product.dart';
import 'model_3d_viewer.dart';


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

  @override
  void initState() {
    super.initState();
    workflowViewModel = WorkflowViewModel();
    productViewModel = ProductViewModel();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final workflows = await workflowViewModel.fetchAllWorkflows();
      setState(() {
        workflowsdata = workflows;
        isLoading = false;
      });
      
      // Preload products for each workflow
      for (var workflow in workflows) {
        if (workflow.product_id != null) {
          await _loadProduct(workflow.product_id!);
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProduct(int productId) async {
    if (!productsCache.containsKey(productId)) {
      final product = await productViewModel.getProductById(productId.toString());
      setState(() {
        productsCache[productId] = product;
      });
    }
  }

  void _show3dModelPopup(String modelPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('3D Model Preview'),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB5927F),
        title: const Padding(
          padding: EdgeInsets.only(left: 120),
          child: Text(
            'Products List',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4e3a31),
              fontFamily: 'BrandonGrotesque'
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: const Color(0xFF4e3a31).withOpacity(.70),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workflowsdata.isEmpty
              ? const Center(child: Text('No workflows found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: workflowsdata.length,
                  itemBuilder: (context, index) {
                    final workflow = workflowsdata[index];
                    final product = workflow.product_id != null 
                        ? productsCache[workflow.product_id!]
                        : null;
                    
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
                                            workflow.name ?? 'Unnamed Workflow',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4e3a31),
                                              fontFamily: 'BrandonGrotesque',
                                              letterSpacing: 0.3,
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
                                      const Text(
                                        'Associated Product',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4e3a31),
                                          fontFamily: 'BrandonGrotesque',
                                          fontSize: 16,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name ?? 'Unnamed Product',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'BrandonGrotesque',
                                                ),
                                              ),
                                              Text(
                                                'Status: ${_getStatusText(product.status_id)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'BrandonGrotesque',
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (product.modelFileName != null && 
                                              product.modelFileName!.isNotEmpty)
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFB5927F),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                              ),
                                              onPressed: () => _show3dModelPopup(
                                                product.modelFileName!),
                                              child: const Text(
                                                'View 3D Model',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'No associated product',
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
    );
  }

  String _getStatusText(int? statusId) {
    switch (statusId) {
      case 1:
        return 'Pending';
      case 2:
        return 'In Progress';
      case 3:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}