import 'dart:async';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage('Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage(this.title) : super();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class DataFetcherService {
  int _fetchCounter = 0;

  Future<String> fetchSomeText() {
    _fetchCounter++;
    if (_fetchCounter % 3 == 0) {
      return Future.delayed(Duration(seconds: 2)).then((_) => Future.error("Some Data Fetching Error"));
    } else {
      return Future.delayed(Duration(seconds: 2)).then((value) => faker.person.name());
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  DataFetcherService _dataFetcher = DataFetcherService();
  StreamController<void> _dataRequests$ = StreamController<void>();

  late Stream<String> _data$;

  bool _isFetching = false;

  void _setIsFetching(bool isFetching) {
    setState(() {
      _isFetching = isFetching;
    });
  }

  @override
  void initState() {
    _data$ = _dataRequests$.stream
        .doOnData((_) => _setIsFetching(true))
        .asyncMap((_) => _dataFetcher.fetchSomeText())
        .doOnEach((_) => _setIsFetching(false));

    _dataRequests$.add(Null);

    super.initState();
  }

  void dispose() {
    _dataRequests$.close();
    super.dispose();
  }

  Widget _renderError(Object error) {
    return Text(
      'Error: ${error.toString()}',
      style: TextStyle(fontSize: 15, color: Colors.red),
    );
  }

  Widget _renderSpinner({required double size, required Color color}) {
    return SizedBox(
      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(color)),
      width: size,
      height: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
        stream: _data$,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Fetched Text below:',
                  ),
                  Text(
                    snapshot.data ?? "",
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  if (snapshot.hasError) _renderError(snapshot.error!),
                  if (snapshot.connectionState == ConnectionState.waiting) _renderSpinner(size: 60, color: Colors.blue),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _isFetching ? null : () => _dataRequests$.add(Null),
              tooltip: 'Fetch more data',
              label: Text(snapshot.connectionState == ConnectionState.waiting ? "Waiting for data" : "Fetch more data"),
              icon: _isFetching && snapshot.connectionState != ConnectionState.waiting
                  ? _renderSpinner(size: 20, color: Colors.white)
                  : null,
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
        });
  }
}
